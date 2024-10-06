{ ... }: {
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 24;

        modules-left = [ "custom/nix" "hyprland/workspaces" ];
        modules-right = [ "pulseaudio" "network" "clock" ];

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

        "hyprland/window" = { "separate-outputs" = true; };

        "clock" = {
          "interval" = 60;
          "format" = "{:%a %d/%m %I:%M}";
        };

        "network" = {
          "interface" = "wlp3s0";
          "format" = "{ifname}";
          "format-wifi" = "<span color='#b4befe'> </span> {essid}";
          "format-ethernet" = "{ipaddr}/{cidr} ";
          "format-disconnected" = "<span color='#b4befe'>󰖪 </span> No Network";
          "tooltip" = false;
        };

        "pulseaudio" = {
          "format" = "<span color='#b4befe'>{icon}</span> {volume}%";
          "format-muted" = "";
          "tooltip" = false;
          "format-icons" = {
            "headphone" = "";
            "default" = [ "" "" "󰕾" "󰕾" "󰕾" "" "" "" ];
          };
          "scroll-step" = 5;
          "on-click" = "pavucontrol";
        };
      };
    };

    style = ''
      * {
        border: none;
        font-family: 'Fira Code', 'Symbols Nerd Font Mono';
        font-size: 16px;
        font-feature-settings: '"zero", "ss01", "ss02", "ss03", "ss04", "ss05", "cv31"';
      }

      window#waybar {
        background: transparent;
      }

      #custom-nix, 
      #workspaces {
        border-radius: 10px;
        background-color: #11111b;
        color: #b4befe;
        padding-left: 10px;
        padding-right: 10px;
      }

      #custom-nix {
        font-size: 20px;
        margin-left: 15px;
        color: #b4befe;
      }

      #workspaces button.active {
        background: #11111b;
        color: #b4befe;
      }

      #clock, #pulseaudio, #network {
        border-radius: 10px;
        background-color: #11111b;
        color: #cdd6f4;
        padding-left: 10px;
        padding-right: 10px;
        margin-right: 15px;
      }

      #pulseaudio, #network {
        border-top-left-radius: 0;
        border-bottom-left-radius: 0;
        padding-left: 5px;
      }

      #clock {
        margin-right: 0;
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
