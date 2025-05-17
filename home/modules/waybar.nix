{
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";

        modules-left = [ "hyprland/workspaces" ];
        modules-right =
          [ "custom/music" "pulseaudio" "backlight" "battery" "clock" "tray" ];

        "hyprland/workspaces" = {
          "format" = "{icon}";
          "format-icons" = { "default" = ""; };
        };

        "tray" = {
          "icon-size" = 21;
          "spacing" = 10;
        };

        "custom/music" = {
          "return-type" = "json";
          "exec" = "waybar-mpris --interpolate --order 'ARTIST:TITLE'";
          "on-click" = "waybar-mpris --send toggle";
          "on-click-right" = "waybar-mpris --send player-next";
          "escape" = true;
          "max-length" = 32;
        };

        "clock" = {
          "tooltip-format" = ''
            <big>{:%Y %B}</big>
            <tt><small>{calendar}</small></tt>'';
          "format-alt" = " {:%d/%m/%Y}";
          "format" = "{:%a %b %d  %H:%M:%S}";
          "interval" = 1;
        };

        "pulseaudio" = {
          "scroll-step" = 5;
          "format" = "{icon} {volume}%";
          "format-muted" = "";
          "format-icons" = { "default" = [ "" "" " " ]; };
          "on-click" = "pavucontrol";
        };
      };
    };

    style = ''
      * {
        font-family: FantasqueSansM Nerd Font;
        font-size: 18px;
        min-height: 0;
      }

      #waybar {
        background: transparent;
        color: @text;
        margin: 5px 5px;
      }

      #workspaces {
        border-radius: 1rem;
        margin: 5px;
        background-color: @surface0;
        margin-left: 1rem;
      }

      #workspaces button {
        color: @lavender;
        border-radius: 1rem;
        padding: 0.4rem;
        padding-right: 0.7rem;
      }

      #workspaces button.active {
        color: @sky;
        border-radius: 1rem;
      }

      #workspaces button:hover {
        color: @sapphire;
        border-radius: 1rem;
      }

      #custom-music,
      #tray,
      #clock,
      #pulseaudio {
        background-color: @surface0;
        padding: 0.5rem 1rem;
        margin: 5px 0;
      }

      #clock {
        color: @blue;
        border-radius: 0px 1rem 1rem 0px;
        margin-right: 1rem;
      }

      #pulseaudio {
        color: @maroon;
        border-radius: 1rem 0px 0px 1rem;
        margin-left: 1rem;
      }

      #custom-music {
        color: @mauve;
        border-radius: 1rem;
      }

      #tray {
        margin-right: 1rem;
        border-radius: 1rem;
      }
    '';
  };
}
