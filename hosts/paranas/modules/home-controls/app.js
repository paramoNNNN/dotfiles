'use strict';
const $ = id => document.getElementById(id);
let state = null, busy = false, reading = false, epoch = 0, dragging = false, unlocked = false, fastUntil = 0;
const mutating = () => document.querySelectorAll('#controls button, #controls select, #controls input');
function message(text, error = false) { $('feedback').textContent = text; $('feedback').classList.toggle('error', error); }
function connection(text, live = false) { $('connection').lastElementChild.textContent = text; $('connection').classList.toggle('live', live); }
function showUnlock() { unlocked = false; $('unlock').hidden = false; $('controls').hidden = true; connection('Locked'); }
async function api(path, body) {
  const abort = new AbortController(), timeout = setTimeout(() => abort.abort(), 65000);
  try {
    const response = await fetch('/tv/api/' + path, {method: body ? 'POST' : 'GET', credentials: 'same-origin', cache: 'no-store', headers: body ? {'Content-Type': 'application/json'} : {}, body: body ? JSON.stringify(body) : undefined, signal: abort.signal});
    const data = await response.json();
    if (!response.ok) { if (response.status === 401 && path !== 'session') showUnlock(); throw new Error(data.error || 'Could not reach Paranas.'); }
    return data;
  } finally { clearTimeout(timeout); }
}
function screenOff() { return /screen\s*off/i.test(state?.powerState || ''); }
function setDisabled() {
  mutating().forEach(el => { el.disabled = busy || !state?.online; });
  $('power').disabled = busy;
  $('music').disabled = busy;
  $('brightness').disabled = busy || !state?.online || !state?.brightnessAdjustable;
  $('pictureMode').disabled = busy || !state?.online || !state?.modes?.length;
}
function button(label, operation, value, secondary) {
  const el = document.createElement('button');
  el.type = 'button'; el.dataset.op = operation; el.dataset.value = value;
  const name = document.createElement('span'); name.textContent = label; el.append(name);
  if (secondary) { const hint = document.createElement('small'); hint.textContent = secondary; el.append(hint); }
  return el;
}
function render(data) {
  state = data; unlocked = true; $('unlock').hidden = true; $('controls').hidden = false;
  const powerText = data.waking ? 'Waking…' : data.online ? (screenOff() ? 'Screen off' : 'TV on') : 'Standby';
  connection(powerText, !!data.online);
  $('power').classList.toggle('on', !!data.online); $('power').lastElementChild.textContent = data.online ? 'Turn off' : 'Wake TV';
  $('power').setAttribute('aria-label', data.online ? 'Turn TV off' : 'Wake TV');
  $('screenLabel').textContent = screenOff() ? 'Screen on' : 'Screen off';
  const source = [...(data.inputs || []), ...(data.apps || [])].find(a => a.id === data.appId);
  const appName = data.appId === 'airplay' ? 'AirPlay' : data.appId === 'com.webos.app.home' ? 'Home' : source?.name;
  $('watching').textContent = data.online ? (appName ? 'LG QNED · ' + appName : 'LG QNED · Ready to watch.') : 'Ready when you are. Wake the TV to get started.';
  $('inputBadge').textContent = (data.input || 'TV').toUpperCase().replace('HDMI', 'HDMI ');
  if (!dragging) { $('brightness').value = data.brightness ?? 0; $('brightnessValue').replaceChildren(document.createTextNode(data.brightness ?? '—')); const percent = document.createElement('small'); percent.textContent = '%'; $('brightnessValue').append(percent); }
  if (document.activeElement !== $('pictureMode')) {
    const modes = data.modes || [], signature = JSON.stringify(modes);
    if ($('pictureMode').dataset.options !== signature) { $('pictureMode').replaceChildren(...(modes.length ? modes.map(x => new Option(x.label, x.value)) : [new Option('Unavailable', '')])); $('pictureMode').dataset.options = signature; }
    $('pictureMode').value = data.pictureMode || '';
  }
  $('pictureHint').textContent = data.online && !data.brightnessAdjustable ? 'Brightness is locked by the current picture settings.' : 'Picture modes follow the current input and HDR signal.';
  $('muteLabel').textContent = data.muted ? 'Unmute' : 'Mute';
  $('volumeHint').textContent = data.optical !== false ? 'Edifier volume needs the Magic Remote awake and pointed at the speakers.' : 'Volume controls the TV’s current sound output.';
  const apps = [{id: 'airplay', name: 'AirPlay'}, ...(data.apps || [])];
  const signature = JSON.stringify(apps);
  if ($('sources').dataset.apps !== signature) {
    $('sources').replaceChildren(...apps.map(app => {
      const el = button(app.name, 'launch', app.id), icon = document.createElement('span');
      icon.className = 'app-icon'; icon.textContent = app.id === 'airplay' ? '◉' : app.name.slice(0, 2).toUpperCase(); el.prepend(icon); return el;
    })); $('sources').dataset.apps = signature;
  }
  const inputs = data.inputs || [], inputsSignature = JSON.stringify(inputs);
  if ($('inputs').dataset.inputs !== inputsSignature) {
    $('inputs').replaceChildren(...inputs.map(input => button(input.name, 'launch', input.id, input.connected ? 'Connected' : 'HDMI ' + input.port))); $('inputs').dataset.inputs = inputsSignature;
  }
  document.querySelectorAll('[data-op="launch"]').forEach(el => el.classList.toggle('active', el.dataset.value === data.appId));
  setDisabled();
}
async function refresh(quiet = false) {
  if (busy || reading || dragging || document.hidden) return;
  reading = true; const version = epoch;
  try { const result = await api('status'); if (version !== epoch || busy) return; render(result); if (!quiet) message('Up to date.'); }
  catch (error) { if (unlocked) connection('Disconnected'); message(error.name === 'AbortError' ? 'The TV took too long to respond. Try Refresh.' : error.message, true); }
  finally { reading = false; setDisabled(); }
}
async function action(op, value) {
  if (busy) return;
  epoch++; busy = true; setDisabled(); message(op === 'music-mode' ? 'Preparing music mode…' : op === 'power-on' ? 'Waking the TV…' : 'Applying…');
  try {
    const result = await api('control', value === undefined ? {op} : {op, value});
    message(result.message || 'Applied.');
    if (op === 'music-mode') $('musicHelp').hidden = false;
    fastUntil = Date.now() + (op === 'power-on' || op === 'music-mode' ? 45000 : 10000);
  } catch (error) { message(error.name === 'AbortError' ? 'The request took too long. Refresh to check the TV.' : error.message, true); }
  finally { busy = false; setDisabled(); await refresh(true); }
}
async function unlock(token) {
  token = token.trim();
  try { if (token.includes('#')) token = new URL(token).hash.slice(1); token = decodeURIComponent(token); }
  catch { message('Paste the full private link or access code.', true); return; }
  try { await api('session', {token}); location.hash = encodeURIComponent(token); $('accessLink').value = ''; await refresh(true); message('Welcome home.'); }
  catch (error) { showUnlock(); message(error.message, true); }
}
$('unlockForm').addEventListener('submit', event => { event.preventDefault(); unlock($('accessLink').value); });
$('power').addEventListener('click', () => action(state?.online ? 'power-off' : 'power-on'));
$('music').addEventListener('click', () => action('music-mode'));
$('screen').addEventListener('click', () => action(screenOff() ? 'screen-on' : 'screen-off'));
$('mute').addEventListener('click', () => action('mute', !state?.muted));
$('brightness').addEventListener('pointerdown', () => { dragging = true; });
$('brightness').addEventListener('input', () => { $('brightnessValue').firstChild.textContent = $('brightness').value; });
$('brightness').addEventListener('change', () => { dragging = false; action('brightness', Number($('brightness').value)); });
$('brightness').addEventListener('pointerup', () => { dragging = false; });
$('brightness').addEventListener('pointercancel', () => { dragging = false; refresh(true); });
$('pictureMode').addEventListener('change', () => action('picture-mode', $('pictureMode').value));
document.addEventListener('click', event => { const key = event.target.closest('[data-key]'), op = event.target.closest('[data-op]'); if (key && !key.disabled) action('key', key.dataset.key); else if (op && !op.disabled) action(op.dataset.op, op.dataset.value); });
$('refresh').addEventListener('click', () => refresh());
$('lock').addEventListener('click', async () => { try { await api('logout', {}); history.replaceState(null, '', location.pathname); showUnlock(); message('Controls locked.'); } catch (error) { message(error.message, true); } });
document.addEventListener('visibilitychange', () => { if (!document.hidden && unlocked) refresh(true); });
setInterval(() => { if (unlocked && (Date.now() < fastUntil || Date.now() % 15000 < 2200)) refresh(true); }, 2000);
if (location.hash.length > 1) unlock(location.hash.slice(1)); else refresh(true);
