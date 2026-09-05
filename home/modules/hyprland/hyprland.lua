-- Hyprland configuration (native Lua format, Hyprland 0.55+).

local terminal = "ghostty"
local fileManager = "nautilus"
local browser = "firefox-devedition"
local mainMod = "SUPER"

hl.monitor({
  output = "",
  mode = "highres",
  position = "auto",
  scale = 1.25,
})

hl.config({
  xwayland = {
    force_zero_scaling = true,
  },
  general = {
    gaps_in = 5,
    gaps_out = 10,
    border_size = 0,
    resize_on_border = false,
    allow_tearing = false,
    layout = "dwindle",
  },
  decoration = {
    rounding = 15,
    active_opacity = 1.0,
    inactive_opacity = 1.0,
    dim_special = 0,
    blur = {
      enabled = false,
    },
    shadow = {
      enabled = false,
    },
  },
  animations = {
    enabled = true,
  },
  dwindle = {
    preserve_split = true,
  },
  misc = {
    force_default_wallpaper = 0,
  },
  input = {
    kb_layout = "us,ir",
    kb_variant = "",
    kb_model = "",
    kb_options = "grp:alt_space_toggle",
    kb_rules = "",
    repeat_rate = 40,
    repeat_delay = 200,
    follow_mouse = 1,
    force_no_accel = false,
    sensitivity = 0,
    touchpad = {
      natural_scroll = true,
      scroll_factor = 0.25,
      clickfinger_behavior = true,
      tap_to_click = false,
    },
  },
  gestures = {
    workspace_swipe_distance = 600,
    workspace_swipe_min_speed_to_force = 2,
  },
})

hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "default" })
hl.animation({ leaf = "fade", enabled = false })
hl.animation({ leaf = "layers", enabled = false })
hl.animation({ leaf = "border", enabled = false })
hl.animation({ leaf = "borderangle", enabled = false })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default" })

hl.on("hyprland.start", function()
  hl.exec_cmd(terminal)
end)

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("GDK_BACKEND", "wayland")

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 4, direction = "up", scale = 0.4, action = "special", workspace_name = "things" })
hl.gesture({ fingers = 4, direction = "down", scale = 0.4, action = "special", workspace_name = "media" })
hl.gesture({ fingers = 4, direction = "left", scale = 0.4, action = "special", workspace_name = "terminal" })
hl.gesture({ fingers = 4, direction = "right", scale = 0.4, action = "special", workspace_name = "woah" })
hl.gesture({ fingers = 4, direction = "pinch", scale = 0.4, action = "fullscreen" })

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exit())
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())

hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

for i = 1, 10 do
  local key = i % 10
  hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

for _, workspace in ipairs({ "media", "things", "terminal", "woah" }) do
  local key = ({ media = "S", things = "D", terminal = "A", woah = "G" })[workspace]
  hl.bind(mainMod .. " + " .. key, hl.dsp.workspace.toggle_special(workspace))
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = "special:" .. workspace }))
end

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind(mainMod .. " + T", hl.dsp.group.toggle())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())

hl.bind("Print", hl.dsp.exec_cmd("screenshot-editor region"))
hl.bind("CTRL + " .. mainMod .. " + R", hl.dsp.exec_cmd("screenshot-editor region"))
hl.bind("CTRL + " .. mainMod .. " + W", hl.dsp.exec_cmd("screenshot-editor window"))
hl.bind("CTRL + " .. mainMod .. " + F", hl.dsp.exec_cmd("gpu-screen-recorder-gtk"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind(mainMod .. " + SHIFT + X", hl.dsp.exec_cmd([[bash "$HOME/.config/fuzzel/colorpicker.sh"]]))

-- DankMaterialShell
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("dms ipc call notifications toggle"))
hl.bind(mainMod .. " + SHIFT + I", hl.dsp.exec_cmd("dms ipc call control-center toggle"))
hl.bind(mainMod .. " + TAB", hl.dsp.exec_cmd("dms ipc call dash toggle overview"))
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd("dms ipc call powermenu toggle"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("dms ipc call processlist focusOrToggle"))
hl.bind(mainMod .. " + SHIFT + Slash", hl.dsp.exec_cmd("dms ipc call keybinds toggle hyprland"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("dms ipc call night toggle"))

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("dms ipc call audio increment 5"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("dms ipc call audio decrement 5"), { locked = true, repeating = true })
hl.bind("XF86Search", hl.dsp.exec_cmd("launchpad"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("dms ipc call audio mute"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("dms ipc call mpris playPause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("dms ipc call mpris next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("dms ipc call mpris previous"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd([[dms ipc call brightness increment 10 ""]]), { locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd([[dms ipc call brightness decrement 10 ""]]), { locked = true })

hl.bind(mainMod .. " + code:51", hl.dsp.exec_cmd("bitwarden"))
hl.bind(mainMod .. " + F1", hl.dsp.exec_cmd("~/.config/hypr/gamemode.sh"))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("vicinae toggle"))
hl.bind("CTRL + " .. mainMod .. " + C", hl.dsp.exec_cmd("vicinae deeplink vicinae://extensions/vicinae/clipboard/history"))
hl.bind("CTRL + " .. mainMod .. " + D", hl.dsp.exec_cmd("vicinae deeplink vicinae://extensions/priithaamer/docker/container_list"))

hl.window_rule({
  name = "suppress-maximize-events",
  match = { class = ".*" },
  suppress_event = "maximize",
})

hl.window_rule({
  name = "bitwarden-float",
  match = { title = "Bitwarden" },
  float = true,
  size = "(monitor_w)/1.25 (monitor_h)/1.25",
  center = true,
})

hl.window_rule({
  name = "qalculate-float",
  match = { title = "Qalculate!" },
  float = true,
  size = "50% 60%",
  center = true,
})
