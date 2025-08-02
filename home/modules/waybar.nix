{ pkgs, lib, inputs, ... }:
let nextmeeting = lib.getExe inputs.nextmeeting.packages.${pkgs.system}.default;
in {
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        margin-bottom = 0;
        margin-top = 10;
        margin-left = 10;
        margin-right = 10;
        spacing = 7;
        height = 45;

        modules-left = [ "hyprland/workspaces" "memory" "custom/agenda" ];
        modules-center = [ "custom/nowplaying" ];
        modules-right =
          [ "network" "pulseaudio" "clock" "custom/notifications" ];

        "custom/notifications" = {
          tooltip = true;
          format = "{icon}";
          format-icons = {
            notification = "<span foreground='red'><sup></sup></span>";
            none = "";
            dnd-notification = "<span foreground='red'><sup></sup></span>";
            dnd-none = "";
            inhibited-notification =
              "<span foreground='red'><sup></sup></span>";
            inhibited-none = "";
            dnd-inhibited-notification =
              "<span foreground='red'><sup></sup></span>";
            dnd-inhibited-none = "";
          };
          return-type = "json";
          exec-if = "which swaync-client";
          exec = "swaync-client -swb";
          on-click = "sleep 0.1 && swaync-client -t -sw";
          on-click-right = "swaync-client -d -sw";
          escape = true;
        };

        "custom/nowplaying" = {
          return-type = "json";
          exec =
            "waybar-mpris --autofocus --interpolate --order 'ARTIST:TITLE'";
          on-click = "playerctl play-pause";
          on-click-right = "playerctl next";
          on-double-click = "playerctl previous";
          escape = true;
          max-length = 64;
        };

        "hyprland/workspaces" = {
          format = "{icon}";
          on-click = "activate";
          format-icons = { "active" = " "; };
          sort-by-number = true;
        };

        clock = {
          format = "{:%H:%M:%S}";
          format-alt = "{:%Y/%m/%d}";
          tooltip-format = "{:%a %B %d}";
          interval = 1;
        };

        network = {
          tooltip = true;
          format-wifi = "";
          format-ethernet = "";
          format-disconnected = "Disconnected ⚠";
        };

        pulseaudio = {
          format = "{icon}  {volume}%";
          tooltip = true;
          format-muted = "󰖁";
          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = "󰓃";
          };
          scroll-step = 5;
          on-click = "pavucontrol";
        };

        memory = {
          interval = 1;
          format = "    {used:0.2f}";
        };

        "custom/agenda" = {
          format = "{}";
          exec = nextmeeting + " --max-title-length 30 --waybar";
          on-click = nextmeeting + " --open-meet-url";
          interval = 59;
          return-type = "json";
          tooltip = true;
        };
      };
    };

    style = ''
      * {
        font-family: "SF Compact Rounded";
        font-size: 17.5px;
      }

      tooltip label {
        color: @base05;
        text-shadow: none;
      }

      window#waybar {
        background-color: transparent;
      }

      #window {
        padding: 0 7px;
        color: @base05;
      }

      #pulseaudio {
        padding: 0 7px;
        color: @base05;
      }
      #pulseaudio.muted {
        padding: 0 7px;
        color: @base08;
      }

      #network {
        padding: 0 9px 0 7px;
        color: @base05;
      }

      #custom-nowplaying {
        padding: 0 7px;
        padding-right: 0px;
        color: @base05;
      }

      #custom-notifications {
        padding: 0 7px;
        padding-right: 10px;
        color: @base05;
      }

      #clock {
        padding: 0 0px;
        color: @base05;
      }

      #workspaces,
      #memory,
      #custom-agenda {
        border: 1px solid @overlay0;
        border-radius: 15px;
        background-color: @base00;
        padding: 0 7px;
      }

      #memory {
        padding: 0 9px;
      }

      #workspaces button {
        padding: 0 5px;
        background-color: transparent;
        color: @base06;
        border-color: transparent;
      }
      #workspaces button.urgent {
        color: @base08;
      }      
      .modules-left #workspaces button.focused,
      .modules-left #workspaces button.active {
        border-bottom: 0;
      }

      .modules-left {
        background: transparent;
        border: none;
      }
      .modules-right,
      .modules-center {
        border: 1px solid @base02;
        border-radius: 15px;
        background-color: @base00;
        padding: 0 7px;
      }
    '';
  };
}
