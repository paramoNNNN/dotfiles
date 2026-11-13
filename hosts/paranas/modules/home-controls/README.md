# Paranas Home TV controls

Private controls at `https://home.<private.domain>/tv/`, linked from the existing
Homepage dashboard. Safari can save the private access link to the Home Screen.
This is a web dashboard, separate from the Apple Home accessory already paired.

Controls: wake-on-LAN, standby, screen on/off, AirPlay receiver, screen-off music
mode, panel brightness, current-signal picture modes, installed apps, HDMI inputs,
navigation, play/pause, mute, and volume steps. AirPlay streaming starts in the
iPhone's AirPlay picker. Optical Edifier volume still needs an awake Magic Remote
with line of sight to the speakers; the dashboard cannot wake that remote.

The web backend runs only on Paranas loopback port 8088 behind existing HTTPS.
Access is unlocked using a private fragment link; the backend sets a signed,
HttpOnly, Secure, SameSite=Strict cookie lasting 30 days. POST requests require the
exact configured HTTPS origin. Secrets are outside the repository and Nix store:

```
/home/paranas/.local/share/paranas-home-secrets/access-token
/home/paranas/.local/share/paranas-home-secrets/tv_ed25519
```

Systemd copies those files into a restricted credential directory for the dynamic
service user. SSH pins the TV host key and uses no agent or general-purpose key.
On the TV the dedicated key is forced to run
`/usr/bin/python3 /media/developer/lg-home-controls/dashboard_agent.py` with
forwarding and PTYs disabled. The helper accepts only validated JSON operations
over stdin. It uses the existing `tv_controls.py` for picture settings; no TV
daemon is required. The helper and its restricted authorized key are provisioned
separately from the server's NixOS activation.

Rotate the access-token file and restart `paranas-home` to revoke all browser
sessions. Remove only the authorized-key line labeled `paranas-home-controls`
to revoke the server's TV access; preserve the TV's other SSH keys.

The TV Ethernet IP is `192.168.1.126`, MAC `7c:64:6c:5e:e1:43`, LAN `/24`.
Keep DHCP reservations for it and Paranas (`192.168.1.215`). Wake packets leave
Paranas on the home LAN, so waking remains available when accessing the dashboard
remotely. Actual AirPlay audio still requires a network that can reach the TV.

Verification: `python3 test_server.py`, `node --check app.js`, NixOS system build,
mobile browser layout/authentication, live TV status/catalog, unchanged mute
write, wake packet while already on, Home, directional keys, AirPlay launch,
screen-off music mode, screen-on, and restoration to the original HDMI input.
A full standby/wake cycle and music play/pause need a convenient live playback
check; they are not claimed as physically verified by the setup checks.

Rollback: remove the `home-controls.nix` import and rebuild NixOS, or activate
the preceding NixOS generation. Existing Homepage services are retained.
