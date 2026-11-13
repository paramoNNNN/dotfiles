import http.client
import importlib.util
import json
from pathlib import Path
import threading
import time
import unittest
from http.server import ThreadingHTTPServer
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('home_server', Path(__file__).with_name('server.py'))
app = importlib.util.module_from_spec(spec)
spec.loader.exec_module(app)


class FakeController:
    def __init__(self):
        self.actions = []

    def status(self):
        return {'online': True, 'brightness': 80, 'modes': []}

    def action(self, data):
        app.validate(data)
        self.actions.append(data)
        return {'message': 'Applied.'}


class AccessTests(unittest.TestCase):
    def test_cookie_tamper_expiry_and_rotation(self):
        access = app.Access('a' * 43, ttl=600)
        signed = access.sign()
        self.assertTrue(access.valid(signed))
        self.assertFalse(access.valid(signed[:-1] + ('a' if signed[-1] != 'a' else 'b')))
        self.assertFalse(app.Access('b' * 43).valid(signed))
        with patch.object(app.time, 'time', return_value=time.time() + 601):
            self.assertFalse(access.valid(signed))

    def test_rate_limit_is_bounded(self):
        access = app.Access('a' * 43)
        self.assertTrue(all(access.allowed_attempt('one') for _ in range(12)))
        self.assertFalse(access.allowed_attempt('one'))
        self.assertTrue(access.allowed_attempt('two'))

    def test_wake_packet(self):
        packet = app.magic_packet()
        self.assertEqual(len(packet), 102)
        self.assertEqual(packet[:6], b'\xff' * 6)
        self.assertEqual(packet[6:], bytes.fromhex('7c646c5ee143') * 16)


class HttpTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.controller = FakeController()
        cls.access = app.Access('secret' * 8)
        cls.server = ThreadingHTTPServer(('127.0.0.1', 0), app.handler_factory(cls.controller, cls.access, ''))
        cls.origin = 'http://127.0.0.1:' + str(cls.server.server_port)
        cls.server.RequestHandlerClass = app.handler_factory(cls.controller, cls.access, cls.origin)
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join()

    def request(self, method, path, data=None, cookie=None, origin=True):
        headers = {}
        if data is not None:
            headers['Content-Type'] = 'application/json'
        if cookie:
            headers['Cookie'] = cookie
        if origin:
            headers['Origin'] = self.origin if origin is True else origin
        connection = http.client.HTTPConnection('127.0.0.1', self.server.server_port, timeout=3)
        connection.request(method, path, body=json.dumps(data) if data is not None else None, headers=headers)
        result = connection.getresponse()
        code, body, response_headers = result.status, result.read(), dict(result.getheaders())
        connection.close()
        return code, body, response_headers

    def login(self):
        code, _, headers = self.request('POST', '/tv/api/session', {'token': self.access.token})
        self.assertEqual(code, 200)
        for flag in ['HttpOnly', 'Secure', 'SameSite=Strict', 'Path=/tv/']:
            self.assertIn(flag, headers['Set-Cookie'])
        return headers['Set-Cookie'].split(';', 1)[0]

    def test_auth_and_read_only_public_assets(self):
        self.assertEqual(self.request('GET', '/tv/')[0], 200)
        self.assertEqual(self.request('GET', '/tv/api/status')[0], 401)
        self.assertEqual(self.request('GET', '/tv/api/status?token=' + self.access.token)[0], 401)
        self.assertEqual(self.request('POST', '/tv/api/control', {'op': 'power-off'})[0], 401)
        self.assertEqual(self.request('GET', '/tv/../../server.py')[0], 404)
        cookie = self.login()
        self.assertEqual(self.request('GET', '/tv/api/status', cookie=cookie)[0], 200)

    def test_csrf_and_untrusted_origin(self):
        self.assertEqual(self.request('POST', '/tv/api/session', {'token': 'invalid\u2603'})[0], 401)
        for origin in [False, 'http://evil.example', 'https://home.example.org.evil.example']:
            self.assertEqual(self.request('POST', '/tv/api/session', {'token': self.access.token}, origin=origin)[0], 403)
        cookie = self.login()
        before = len(self.controller.actions)
        self.assertEqual(self.request('POST', '/tv/api/control', {'op': 'power-off'}, cookie, origin='http://evil.example')[0], 403)
        self.assertEqual(len(self.controller.actions), before)

    def test_actions_are_validated_before_execution(self):
        cookie = self.login()
        for data in [{'op': 'brightness', 'value': 101}, {'op': 'brightness', 'value': True},
                     {'op': 'launch', 'value': 'airplay;reboot'}, {'op': 'key', 'value': 'SHELL'},
                     {'op': 'power-off', 'value': 'extra'}, {'op': []},
                     {'op': 'command', 'value': 'rm -rf /'}, {'op': 'mute', 'value': 'false'}]:
            before = len(self.controller.actions)
            self.assertEqual(self.request('POST', '/tv/api/control', data, cookie)[0], 400, data)
            self.assertEqual(len(self.controller.actions), before)
        self.assertEqual(self.request('POST', '/tv/api/control', {'op': 'brightness', 'value': 79}, cookie)[0], 200)
        self.assertEqual(self.controller.actions[-1], {'op': 'brightness', 'value': 79})


if __name__ == '__main__':
    unittest.main()
