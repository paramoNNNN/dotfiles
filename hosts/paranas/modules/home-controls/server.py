#!/usr/bin/env python3
"""Paranas TV controls: authenticated HTTP, restricted SSH, and LAN wake."""
import argparse
import base64
from collections import defaultdict, deque
import hashlib
import hmac
from http import cookies
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os
from pathlib import Path
import secrets
import socket
import subprocess
import threading
import time
from urllib.parse import urlsplit

TV_HOST = '192.168.1.126'
TV_MAC = '7c:64:6c:5e:e1:43'
OPS = {'power-on', 'power-off', 'screen-on', 'screen-off', 'music-mode',
       'brightness', 'picture-mode', 'launch', 'play', 'pause',
       'volume-up', 'volume-down', 'mute', 'key'}
NO_VALUE = OPS - {'brightness', 'picture-mode', 'launch', 'mute', 'key'}
KEYS = {'UP', 'DOWN', 'LEFT', 'RIGHT', 'ENTER', 'BACK', 'HOME', 'EXIT', 'INFO', 'MENU'}
ROOT = Path(__file__).resolve().parent


def validate(data):
    if not isinstance(data, dict) or set(data) - {'op', 'value'}:
        raise ValueError('Invalid request.')
    op, value = data.get('op'), data.get('value')
    if not isinstance(op, str) or op not in OPS:
        raise ValueError('Unsupported control.')
    if op in NO_VALUE and value is not None:
        raise ValueError('This control does not accept a value.')
    if op == 'brightness' and (type(value) is not int or not 0 <= value <= 100):
        raise ValueError('Brightness must be a whole number from 0 to 100.')
    if op == 'mute' and type(value) is not bool:
        raise ValueError('Mute must be true or false.')
    if op == 'key' and (not isinstance(value, str) or value not in KEYS):
        raise ValueError('Unsupported remote key.')
    if op in ('picture-mode', 'launch') and (
        not isinstance(value, str) or not 1 <= len(value) <= 100
        or not all(c.isascii() and (c.isalnum() or c in '._-') for c in value)
    ):
        raise ValueError('Invalid selection.')
    return data


def magic_packet(mac=TV_MAC):
    address = bytes.fromhex(mac.replace(':', ''))
    if len(address) != 6:
        raise ValueError('Invalid wake address.')
    return b'\xff' * 6 + address * 16


class Controller:
    def __init__(self, identity, known_hosts, ssh='ssh'):
        self.ssh = [ssh, '-F', '/dev/null', '-T', '-o', 'BatchMode=yes',
                    '-o', 'IdentitiesOnly=yes', '-o', 'ConnectTimeout=3',
                    '-o', 'ConnectionAttempts=1', '-o', 'StrictHostKeyChecking=yes',
                    '-o', 'UserKnownHostsFile=' + str(known_hosts), '-i', str(identity),
                    'root@' + TV_HOST, 'dashboard']
        self.lock = threading.RLock()
        self.cached = None
        self.cached_at = 0
        self.catalog = {'apps': [], 'inputs': []}
        self.catalog_at = 0
        self.waking_until = 0

    def request(self, data):
        result = subprocess.run(self.ssh, input=json.dumps(data), text=True,
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=35)
        try:
            reply = json.loads(result.stdout)
        except ValueError:
            raise ConnectionError('The TV is asleep or unavailable. Try Power on.')
        if not reply.get('ok'):
            raise ValueError(reply.get('error', 'The TV rejected the command.'))
        return reply['data']

    def status(self, fresh=False):
        with self.lock:
            if not fresh and self.cached and time.monotonic() - self.cached_at < 3:
                return self.cached
            try:
                state = self.request({'op': 'status'})
                if state['online'] and (not self.catalog_at or time.monotonic() - self.catalog_at > 90):
                    self.catalog = self.request({'op': 'catalog'})
                    self.catalog_at = time.monotonic()
                state.update(self.catalog)
                state['waking'] = not state['online'] and time.monotonic() < self.waking_until
                if state['online']:
                    self.waking_until = 0
            except (ConnectionError, subprocess.TimeoutExpired):
                state = {'online': False, 'powerState': 'Standby',
                         'waking': time.monotonic() < self.waking_until, **self.catalog}
            self.cached, self.cached_at = state, time.monotonic()
            return state

    def wake(self):
        packet = magic_packet()
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as client:
            client.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
            for _ in range(3):
                client.sendto(packet, ('192.168.1.255', 9))
                time.sleep(0.08)
        self.waking_until = time.monotonic() + 40
        self.cached_at = 0

    def action(self, data):
        validate(data)
        op = data['op']
        with self.lock:
            self.cached_at = 0
            if op == 'power-on':
                self.wake()
                return {'message': 'Wake request sent. The TV may take a few seconds.'}
            if op == 'music-mode':
                if not self.status(fresh=True)['online']:
                    self.wake()
                    for _ in range(7):
                        time.sleep(2)
                        if self.status(fresh=True)['online']:
                            break
                    else:
                        raise ConnectionError('Wake request sent. When the TV starts, tap Music mode again.')
                # Keep an existing AirPlay stream running; otherwise open the receiver.
                state = self.status()
                if state.get('appId') != 'airplay':
                    self.request({'op': 'launch', 'value': 'airplay'})
                    time.sleep(2)
                self.request({'op': 'screen-off'})
                self.cached_at = 0
                return {'message': 'Music mode ready. Choose the LG TV in your iPhone’s AirPlay picker.'}
            try:
                self.request(data)
            except ConnectionError:
                if op != 'power-off':
                    raise
                # Power-off can close SSH before its acknowledgement arrives.
                return {'message': 'Power-off request sent. Checking the TV’s status…'}
            self.cached_at = 0
            return {'message': 'Applied.'}


class Access:
    def __init__(self, token, ttl=30 * 86400):
        self.token = token
        self.key = hashlib.sha256(('cookie:' + token).encode()).digest()
        self.ttl = ttl
        self.attempts = defaultdict(deque)
        self.lock = threading.Lock()

    def allowed_attempt(self, address):
        with self.lock:
            now = time.monotonic()
            bucket = self.attempts[address]
            while bucket and bucket[0] < now - 60:
                bucket.popleft()
            if len(bucket) >= 12:
                return False
            bucket.append(now)
            # Bound unauthenticated rate-limit memory on an internet-facing service.
            if len(self.attempts) > 4096:
                self.attempts = defaultdict(deque, {address: bucket})
            return True

    def sign(self):
        payload = '{}:{}'.format(int(time.time()) + self.ttl, secrets.token_hex(12))
        signature = hmac.new(self.key, payload.encode(), hashlib.sha256).hexdigest()
        return payload + ':' + signature

    def valid(self, value):
        try:
            expiry, nonce, signature = value.split(':')
            if not int(time.time()) < int(expiry) <= int(time.time()) + self.ttl + 60:
                return False
            payload = expiry + ':' + nonce
            expected = hmac.new(self.key, payload.encode(), hashlib.sha256).hexdigest()
            return hmac.compare_digest(signature, expected)
        except (ValueError, TypeError):
            return False


def handler_factory(controller, access, origin, prefix='/tv', secure=True):
    assets = {
        '/': ('index.html', 'text/html; charset=utf-8'),
        '/app.js': ('app.js', 'text/javascript; charset=utf-8'),
        '/styles.css': ('styles.css', 'text/css; charset=utf-8'),
        '/icon.svg': ('icon.svg', 'image/svg+xml'),
        '/apple-touch-icon.png': ('apple-touch-icon.png', 'image/png'),
        '/manifest.webmanifest': ('manifest.webmanifest', 'application/manifest+json'),
    }

    class Handler(BaseHTTPRequestHandler):
        server_version = 'ParanasHome'

        def setup(self):
            super().setup()
            self.connection.settimeout(15)

        def log_message(self, *_):
            pass

        def reply(self, code, data, kind='application/json', cookie=None):
            body = json.dumps(data).encode() if isinstance(data, dict) else data
            self.send_response(code)
            self.send_header('Content-Type', kind)
            self.send_header('Content-Length', str(len(body)))
            self.send_header('Cache-Control', 'no-store')
            self.send_header('X-Content-Type-Options', 'nosniff')
            self.send_header('Referrer-Policy', 'no-referrer')
            self.send_header('X-Frame-Options', 'DENY')
            self.send_header('Content-Security-Policy', "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'")
            if cookie:
                self.send_header('Set-Cookie', cookie)
            self.end_headers()
            self.wfile.write(body)

        def authenticated(self):
            jar = cookies.SimpleCookie()
            try:
                jar.load(self.headers.get('Cookie', ''))
                return access.valid(jar['paranas_tv'].value) if 'paranas_tv' in jar else False
            except cookies.CookieError:
                return False

        def route(self):
            path = urlsplit(self.path).path
            if not path.startswith(prefix + '/'):
                return ''
            return path[len(prefix):]

        def do_GET(self):
            route = self.route()
            if route in assets:
                name, mime = assets[route]
                return self.reply(200, (ROOT / name).read_bytes(), mime)
            if route != '/api/status':
                return self.reply(404, {'error': 'Not found.'})
            if not self.authenticated():
                return self.reply(401, {'error': 'Open your private access link to unlock the TV controls.'})
            try:
                self.reply(200, controller.status())
            except (ValueError, ConnectionError, subprocess.SubprocessError):
                self.reply(503, {'error': 'Could not read the TV. Please try again.'})

        def do_POST(self):
            route = self.route()
            if route not in ('/api/session', '/api/control', '/api/logout'):
                return self.reply(404, {'error': 'Not found.'})
            # Validate the configured HTTPS origin, never forwarded/Host input.
            if self.headers.get('Origin') != origin:
                return self.reply(403, {'error': 'Invalid origin.'})
            if self.headers.get('Content-Type') != 'application/json':
                return self.reply(415, {'error': 'JSON is required.'})
            try:
                length = int(self.headers.get('Content-Length', '0'))
                if not 1 <= length <= 1024:
                    raise ValueError('Invalid request size.')
                data = json.loads(self.rfile.read(length))
                if not isinstance(data, dict):
                    raise ValueError('Invalid request.')
            except (ValueError, TypeError):
                return self.reply(400, {'error': 'Invalid request.'})
            suffix = '; Path=' + prefix + '/; HttpOnly; SameSite=Strict' + ('; Secure' if secure else '')
            if route == '/api/session':
                address = self.headers.get('X-Real-IP', self.client_address[0])
                if not access.allowed_attempt(address):
                    return self.reply(429, {'error': 'Too many attempts. Try again in a minute.'})
                token = data.get('token')
                if not isinstance(token, str) or not token.isascii() or not hmac.compare_digest(token, access.token):
                    return self.reply(401, {'error': 'Invalid private link.'})
                return self.reply(200, {'ok': True}, cookie='paranas_tv=' + access.sign() + '; Max-Age=' + str(access.ttl) + suffix)
            if not self.authenticated():
                return self.reply(401, {'error': 'Open your private access link to unlock the TV controls.'})
            if route == '/api/logout':
                return self.reply(200, {'ok': True}, cookie='paranas_tv=; Max-Age=0' + suffix)
            try:
                self.reply(200, controller.action(data))
            except ValueError as exc:
                self.reply(400, {'error': str(exc)})
            except ConnectionError as exc:
                self.reply(503, {'error': str(exc)})
            except subprocess.SubprocessError:
                self.reply(504, {'error': 'The TV took too long to answer. Refresh to check its state.'})

    return Handler


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--bind', default='127.0.0.1')
    parser.add_argument('--port', type=int, default=8088)
    parser.add_argument('--origin', required=True)
    parser.add_argument('--token-file', required=True, type=Path)
    parser.add_argument('--identity', required=True, type=Path)
    parser.add_argument('--known-hosts', required=True, type=Path)
    parser.add_argument('--ssh', default='ssh')
    parser.add_argument('--insecure-cookie', action='store_true')
    args = parser.parse_args()
    token = args.token_file.read_text().strip()
    if len(token) < 32:
        raise RuntimeError('The access token must contain at least 32 random characters.')
    controller = Controller(args.identity, args.known_hosts, args.ssh)
    handler = handler_factory(controller, Access(token), args.origin, secure=not args.insecure_cookie)
    server = ThreadingHTTPServer((args.bind, args.port), handler)
    print('Paranas TV controls listening on {}:{}'.format(args.bind, args.port), flush=True)
    server.serve_forever()


if __name__ == '__main__':
    main()
