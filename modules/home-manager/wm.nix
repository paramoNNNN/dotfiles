{ ... }: {
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 40;

        modules-left = [ "custom/nix" "hyprland/workspaces" ];
        modules-center = [ "hyprland/window" ];
        modules-right =
          [ "custom/mpris" "pulseaudio" "network" "clock" "tray" ];

        "custom/nix" = {
          "format" = "";
          "tooltip" = false;
          "on-click" = ''
            bemenu-run --accept-single  -n -p "Launch" --hp 4 --hf "#ffffff" --sf "#ffffff" --tf "#ffffff" '';
        };

        "hyprland/workspaces" = {
          "format" = "{icon}";
          "on-scroll-up" = "hyprctl dispatch workspace e+1";
          "on-scroll-down" = "hyprctl dispatch workspace e-1";
        };

        "hyprland/window" = {
          "separate-outputs" = true;
          "max-length" = 64;
        };

        "tray" = {
          "icon-size" = 22;
          "spacing" = 6;
        };

        "clock" = {
          "interval" = 1;
          "format" = "{:%a %b %d  %H:%M:%S}";
        };

        "network" = {
          "interface" = "wlo1";
          "format" = "{ifname}";
          "format-wifi" = "<span color='#7aa2f7'> </span> {essid}";
          "format-ethernet" = "{ipaddr}/{cidr} ";
          "format-disconnected" = "<span color='#b4befe'>󰖪  </span> No Network";
          "tooltip" = false;
        };

        "pulseaudio" = {
          "scroll-step" = 5;
          "format" = ''<span color="#7aa2f7">{icon} </span>{volume}%'';
          "format-muted" = ''<span color="#f7768e"> </span>Muted'';
          "format-icons" = [ "" "" "" ];
          "on-click" = "pavucontrol";
          "interval" = 4;
        };

        "custom/mpris" = {
          "return-type" = "json";
          "exec" = "waybar-mpris --interpolate --order 'ARTIST:TITLE'";
          "on-click" = "waybar-mpris --send toggle";
          "on-click-right" = "waybar-mpris --send player-next";
          "escape" = true;
          "max-length" = 32;
        };
      };
    };

    style = ''
      .module,
      #clock,
      #workspaces button {
        background: transparent;
        padding: 2px 10px;
        font-family:
          SpaceMono Nerd Font,
          feather;
        font-weight: 900;
        font-size: 10pt;
        color: #c0caf5;
      }


      window#waybar {
        background: rgba(17, 17, 27, 0.95);
        border: 2px solid #414868;
      }

      #workspaces {
        padding-right: 0;
      }

      #workspaces button {
        padding: 2px 4px;
      }

      #workspaces button.active {
        border-bottom: 2px solid #7aa2f7;
        border-radius: 0;
        margin-top: 2px;
        transition: none;
      }

      #workspaces button.focused {
        color: #a6adc8;
      }

      #workspaces button.urgent {
          color: #f7768e;
      }

      #workspaces button:hover {
        background: #11111b;
        color: #cdd6f4;
      }

      tooltip {
        background: #1e1e2e;
        border-radius: 0;
      }

      #tray {
        margin-right: 4px;
      }
    '';

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
}
