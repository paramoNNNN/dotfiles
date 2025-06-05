{
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

        modules-left = [ "hyprland/workspaces" "memory" ];
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
          on-double-click = "playerctl next";
          on-triple-click = "playerctl previous";
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
          format = "{icon} {volume}%";
          tooltip = true;
          format-muted = "󰖁 ";
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
          format = "  {used:0.2f}";
        };
      };
    };

    style = ''
      * {
        font-family: "monospace";
        font-size: 16px;
      }

      window#waybar {
        background-color: transparent;
      }

      #window {
        padding: 0 7px;
        color: @text;
      }

      #pulseaudio {
        padding: 0 7px;
        color: @text;
      }
      #pulseaudio.muted {
        padding: 0 7px;
        color: @red;
      }

      #network {
        padding: 0 9px 0 7px;
        color: @text;
      }

      #custom-nowplaying {
        padding: 0 7px;
        padding-right: 0px;
        color: @text;
      }

      #custom-notifications {
        padding: 0 7px;
        padding-right: 10px;
        color: @text;
      }

      #clock {
        padding: 0 0px;
        color: @text;
      }

      #workspaces,
      #memory {
        border: 1px solid @overlay0;
        border-radius: 15px;
        background-color: @crust;
        padding: 0 7px;
      }

      #memory {
        padding: 0 9px;
      }

      #workspaces button {
        padding: 0 5px;
        background-color: transparent;
        color: @blue;
      }
      #workspaces button.urgent {
        color: @red;
      }

      .modules-left {
        background: transparent;
        border: none;
      }
      .modules-right,
      .modules-center {
        border: 1px solid @overlay0;
        border-radius: 15px;
        background-color: @crust;
        padding: 0 7px;
      }
    '';
  };
}
