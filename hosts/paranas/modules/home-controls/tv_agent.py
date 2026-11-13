#!/usr/bin/python3
"""Restricted stdin JSON gateway; the dashboard SSH key can only run this file."""
import json
import shlex
import subprocess
import sys

sys.path.insert(0, '/media/developer/lg-home-controls')
from tv_controls import TV

KEYS = {'UP', 'DOWN', 'LEFT', 'RIGHT', 'ENTER', 'BACK', 'HOME', 'EXIT', 'INFO', 'MENU'}
KEY_CODES = {'UP': 103, 'DOWN': 108, 'LEFT': 105, 'RIGHT': 106,
             'ENTER': 28, 'BACK': 412, 'EXIT': 174, 'INFO': 358, 'MENU': 139}
HIDDEN_APPS = {
    'org.webosbrew.hbchannel', 'org.webosbrew.inputhook',
    'org.webosbrew.custom-screensaver', 'amazon.alexa.view',
}


def luna(uri, payload=None):
    command = ' '.join(shlex.quote(x) for x in [
        '/usr/bin/luna-send', '-n', '1', '-w', '5000', 'luna://' + uri,
        json.dumps(payload or {}, separators=(',', ':')),
    ])
    result = subprocess.run(
        ['/usr/bin/script', '-q', '-e', '-c', command, '/dev/null'],
        stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
        stderr=subprocess.PIPE, text=True, timeout=8,
    )
    for line in result.stdout.splitlines():
        try:
            data = json.loads(line)
        except ValueError:
            continue
        if isinstance(data, dict):
            if data.get('returnValue') is True and result.returncode == 0:
                return data
            raise RuntimeError(data.get('errorText', 'The TV rejected the command.'))
    raise RuntimeError('The TV did not confirm the command.')


def catalog():
    apps = luna('com.webos.applicationManager/listLaunchPoints').get('launchPoints', [])
    inputs = luna('com.webos.service.apiadapter/tv/getExternalInputList').get('devices', [])
    return {
        'apps': [{'id': a['id'], 'name': a.get('title', a['id'])}
                 for a in apps if not a.get('systemApp') and a['id'] not in HIDDEN_APPS],
        'inputs': [{'id': d['appId'], 'name': d.get('spdProductDescription') or d.get('label', d['id']),
                    'port': d.get('port'), 'connected': bool(d.get('hdmiSignalExist'))}
                   for d in inputs if d.get('appId', '').startswith('com.webos.app.hdmi')],
    }


def execute(data):
    if not isinstance(data, dict) or set(data) - {'op', 'value'}:
        raise ValueError('Invalid request.')
    op, value = data.get('op'), data.get('value')
    if not isinstance(op, str):
        raise ValueError('Invalid operation.')
    if op == 'status':
        state = {'online': True}
        state['powerState'] = luna('com.webos.service.tvpower/power/getPowerState')['state']
        state['online'] = state['powerState'].replace(' ', '').lower() in {'active', 'screenoff', 'screensaver'}
        if not state['online']:
            return state
        state['appId'] = luna('com.webos.applicationManager/getForegroundAppInfo').get('appId', '')
        volume = luna('com.webos.service.audio/master/getVolume').get('volumeStatus', {})
        state['volume'] = volume.get('volume')
        state['muted'] = volume.get('muteStatus', volume.get('muted', False))
        state['optical'] = volume.get('soundOutput') == 'urcu_oss'
        try:
            state.update(TV().status(fresh=True))
        except Exception:
            state.update(brightness=None, brightnessAdjustable=False, modes=[], pictureMode='')
        return state
    if op == 'catalog':
        return catalog()
    if op == 'brightness':
        return TV().set('brightness', value)
    if op == 'picture-mode':
        return TV().set('pictureMode', value)
    if op in ('screen-on', 'screen-off'):
        power = luna('com.webos.service.tvpower/power/getPowerState')['state']
        is_off = power.replace(' ', '').lower() == 'screenoff'
        if is_off == (op == 'screen-off'):
            return {'returnValue': True, 'state': power}
        return luna('com.webos.service.tvpower/power/' + ('turnOnScreen' if op == 'screen-on' else 'turnOffScreen'))
    if op == 'power-off':
        return luna('com.webos.service.tvpower/power/powerOff', {'reason': 'remoteKey'})
    if op == 'launch':
        available = catalog()
        allowed = {a['id'] for a in available['apps'] + available['inputs']}
        allowed.update({'airplay', 'com.webos.app.home'})
        if not isinstance(value, str) or value not in allowed:
            raise ValueError('That app or input is unavailable.')
        return luna('com.webos.applicationManager/launch', {'id': value})
    if op in ('play', 'pause'):
        return luna('com.webos.service.networkinput/controls/' + op)
    if op in ('volume-up', 'volume-down'):
        # The TV forwards these steps to its configured universal audio remote.
        return luna('com.webos.service.audio/master/' + ('volumeUp' if op == 'volume-up' else 'volumeDown'))
    if op == 'mute':
        if type(value) is not bool:
            raise ValueError('Mute must be true or false.')
        return luna('com.webos.service.audio/master/muteVolume', {'mute': value})
    if op == 'key':
        if not isinstance(value, str) or value not in KEYS:
            raise ValueError('Unsupported remote key.')
        if value == 'HOME':
            return luna('com.webos.applicationManager/launch', {'id': 'com.webos.app.home'})
        return luna('com.webos.service.networkinput/test/sendKeyCode', {'keyCode': KEY_CODES[value]})
    raise ValueError('Unsupported operation.')


if __name__ == '__main__':
    try:
        raw = sys.stdin.buffer.read(1025)
        if len(raw) > 1024:
            raise ValueError('Request is too large.')
        result = execute(json.loads(raw))
        print(json.dumps({'ok': True, 'data': result}), flush=True)
    except Exception as exc:
        print(json.dumps({'ok': False, 'error': str(exc)}), flush=True)
        sys.exit(1)
