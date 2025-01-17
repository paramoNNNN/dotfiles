{ pkgs, ... }: {
  imports = [ ./cliphist.nix ./gtk.nix ./swaync.nix ./waybar.nix ./wofi.nix ];

  # Consistent cursor theme across all applications.
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.yaru-theme;
    name = "Yaru";
    size = 24;
  };

  wayland.windowManager.hyprland = {
    xwayland.enable = true;
    settings = {
      "$mod" = "SUPER";
      bind = [ "$mod, F, exec, firefox" ", Print, exec, grimblast copy area" ]
        ++ (
          # workspaces
          # binds $mod + [shift +] {1..10} to [move to] workspace {1..10}
          builtins.concatLists (builtins.genList (x:
            let
              ws = let c = (x + 1) / 10;
              in builtins.toString (x + 1 - (c * 10));
            in [
              "$mod, ${ws}, workspace, ${toString (x + 1)}"
              "$mod SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
            ]) 10));
    };
  };

  # Source hyprland config from the home-manager store
  # xdg.configFile = {
  #   "hypr" = {
  #     recursive = true;
  #     source = "${hyprland_config}";
  #   };
  #
  #   "hypr/hyprpaper.conf".text = ''
  #     splash = false
  #     preload = ${wallpaper}
  #     wallpaper = DP-1, ${wallpaper}
  #     wallpaper = eDP-1, ${wallpaper}
  #   '';
  #
  #   "hypr/hypridle.conf".text = ''
  #     general {
  #       lock_cmd = pidof hyprlock || hyprlock
  #       before_sleep_cmd = loginctl lock-session
  #       after_sleep_cmd = hyprctl dispatch dpms on
  #     }
  #   '';
  #
  #   "hypr/hyprlock.conf".text = ''
  #     background {
  #         monitor =
  #         path = ${wallpaper}
  #         blur_passes = 3
  #         contrast = 0.8916
  #         brightness = 0.8172
  #         vibrancy = 0.1696
  #         vibrancy_darkness = 0.0
  #     }
  #
  #     general {
  #         no_fade_in = false
  #         grace = 0
  #         disable_loading_bar = true
  #     }
  #
  #     # DP-1 Conifg
  #     input-field {
  #         monitor = DP-1
  #         size = 250, 60
  #         outline_thickness = 2
  #         dots_size = 0.2 # Scale of input-field height, 0.2 - 0.8
  #         dots_spacing = 0.2 # Scale of dots' absolute size, 0.0 - 1.0
  #         dots_center = true
  #         outer_color = rgba(0, 0, 0, 0)
  #         inner_color = rgba(0, 0, 0, 0.5)
  #         font_color = rgb(200, 200, 200)
  #         fade_on_empty = false
  #         capslock_color = -1
  #         placeholder_text = <i><span foreground="##e6e9ef">Password</span></i>
  #         fail_text = <i>$FAIL <b>($ATTEMPTS)</b></i>
  #         hide_input = false
  #         position = 0, -120
  #         halign = center
  #         valign = center
  #     }
  #
  #     # Date
  #     label {
  #       monitor = DP-1
  #       text = cmd[update:1000] echo "<span>$(date '+%A, %d %B')</span>"
  #       color = rgba(255, 255, 255, 0.8)
  #       font_size = 15
  #       font_family = JetBrains Mono Nerd Font Mono ExtraBold
  #       position = 0, -400
  #       halign = center
  #       valign = top
  #     }
  #
  #     # Time
  #     label {
  #         monitor = DP-1
  #         text = cmd[update:1000] echo "<span>$(date '+%H:%M')</span>"
  #         color = rgba(255, 255, 255, 0.8)
  #         font_size = 120
  #         font_family = JetBrains Mono Nerd Font Mono ExtraBold
  #         position = 0, -400
  #         halign = center
  #         valign = top
  #     }
  #
  #     # Keyboard layout
  #     label {
  #       monitor = DP-1
  #       text = $LAYOUT
  #       color = rgba(255, 255, 255, 0.9)
  #       font_size = 10
  #       font_family = JetBrains Mono Nerd Font Mono
  #       position = 0, -175
  #       halign = center
  #       valign = center
  #     }
  #
  #     # eDP-1 Conifg
  #     input-field {
  #         monitor = eDP-1
  #         size = 500, 120
  #         outline_thickness = 2
  #         dots_size = 0.2 # Scale of input-field height, 0.2 - 0.8
  #         dots_spacing = 0.2 # Scale of dots' absolute size, 0.0 - 1.0
  #         dots_center = true
  #         outer_color = rgba(0, 0, 0, 0)
  #         inner_color = rgba(0, 0, 0, 0.5)
  #         font_color = rgb(200, 200, 200)
  #         fade_on_empty = false
  #         capslock_color = -1
  #         placeholder_text = <i><span foreground="##e6e9ef">Password</span></i>
  #         fail_text = <i>$FAIL <b>($ATTEMPTS)</b></i>
  #         hide_input = false
  #         position = 0, -120
  #         halign = center
  #         valign = center
  #     }
  #
  #     # Date
  #     label {
  #       monitor = eDP-1
  #       text = cmd[update:1000] echo "<span>$(date '+%A, %d %B')</span>"
  #       color = rgba(255, 255, 255, 0.8)
  #       font_size = 30
  #       font_family = JetBrains Mono Nerd Font Mono ExtraBold
  #       position = 0, -400
  #       halign = center
  #       valign = top
  #     }
  #
  #     # Time
  #     label {
  #         monitor = eDP-1
  #         text = cmd[update:1000] echo "<span>$(date '+%H:%M')</span>"
  #         color = rgba(255, 255, 255, 0.8)
  #         font_size = 240
  #         font_family = JetBrains Mono Nerd Font Mono ExtraBold
  #         position = 0, -400
  #         halign = center
  #         valign = top
  #     }
  #
  #     # Keyboard layout
  #     label {
  #       monitor = eDP-1
  #       text = $LAYOUT
  #       color = rgba(255, 255, 255, 0.9)
  #       font_size = 20
  #       font_family = JetBrains Mono Nerd Font Mono
  #       position = 0, -230
  #       halign = center
  #       valign = center
  #     }
  #   '';
  # };
}
