{ pkgs, ... }: {
  imports =
    [ ../cliphist.nix ../gtk.nix ../swaync.nix ../waybar.nix ../fuzzel.nix ];

  # Consistent cursor theme across all applications.
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.yaru-theme;
    name = "Yaru";
    size = 24;
  };

  wayland.windowManager.hyprland = { xwayland.enable = true; };

  xdg.configFile = {
    "hypr/hyprland.conf" = { source = ./hyprland.conf; };

    "hypr/hypridle.conf".text = ''
      general {
        lock_cmd = pidof hyprlock || hyprlock
      }
    '';

    "hypr/hyprlock.conf".text = ''
      $rosewater = rgb(dc8a78)
      $rosewaterAlpha = dc8a78
      $flamingo = rgb(dd7878)
      $flamingoAlpha = dd7878
      $pink = rgb(ea76cb)
      $pinkAlpha = ea76cb
      $mauve = rgb(8839ef)
      $mauveAlpha = 8839ef
      $red = rgb(d20f39)
      $redAlpha = d20f39
      $maroon = rgb(e64553)
      $maroonAlpha = e64553
      $peach = rgb(fe640b)
      $peachAlpha = fe640b
      $yellow = rgb(df8e1d)
      $yellowAlpha = df8e1d
      $green = rgb(40a02b)
      $greenAlpha = 40a02b
      $teal = rgb(179299)
      $tealAlpha = 179299
      $sky = rgb(04a5e5)
      $skyAlpha = 04a5e5
      $sapphire = rgb(209fb5)
      $sapphireAlpha = 209fb5
      $blue = rgb(1e66f5)
      $blueAlpha = 1e66f5
      $lavender = rgb(7287fd)
      $lavenderAlpha = 7287fd
      $text = rgb(4c4f69)
      $textAlpha = 4c4f69
      $subtext1 = rgb(5c5f77)
      $subtext1Alpha = 5c5f77
      $subtext0 = rgb(6c6f85)
      $subtext0Alpha = 6c6f85
      $overlay2 = rgb(7c7f93)
      $overlay2Alpha = 7c7f93
      $overlay1 = rgb(8c8fa1)
      $overlay1Alpha = 8c8fa1
      $overlay0 = rgb(9ca0b0)
      $overlay0Alpha = 9ca0b0
      $surface2 = rgb(acb0be)
      $surface2Alpha = acb0be
      $surface1 = rgb(bcc0cc)
      $surface1Alpha = bcc0cc
      $surface0 = rgb(ccd0da)
      $surface0Alpha = ccd0da
      $base = rgb(eff1f5)
      $baseAlpha = eff1f5
      $mantle = rgb(e6e9ef)
      $mantleAlpha = e6e9ef
      $crust = rgb(dce0e8)
      $crustAlpha = dce0e8

      $accent = $sapphire
      $accentAlpha = $sapphireAlpha
      $font = monospace

      general {
          hide_cursor = true
      }

      background {
          monitor =
          path = $HOME/Pictures/wallpaper-light-2.png
          blur_passes = 3
          contrast = 0.8916
          brightness = 0.8172
          vibrancy = 0.1696
          vibrancy_darkness = 0.0
      }

      # LAYOUT
      label {
        monitor =
        text = $LAYOUT
        color = $base
        font_size = 8
        font_family = $font
        position = 30, -30
        halign = left
        valign = top
      }

      # TIME
      label {
        monitor =
        text = $TIME
        color = $base
        font_size = 90
        font_family = $font
        position = 0, -50
        halign = center
        valign = top
      }

      # DATE
      label {
        monitor =
        text = cmd[update:43200000] date +"%A, %d %B %Y"
        color = $base
        font_size = 25
        font_family = $font
        position = 0, -200
        halign = center
        valign = top
      }

      # USER AVATAR
      image {
        monitor =
        path = $HOME/Pictures/avatar.jpg
        size = 100
        border_color = $accent
        position = 0, 75
        halign = center
        valign = center
      }

      # INPUT FIELD
      input-field {
        monitor =
        size = 300, 60
        outline_thickness = 4
        dots_size = 0.2
        dots_spacing = 0.2
        dots_center = true
        outer_color = $accent
        inner_color = $surface0
        font_color = $text
        fade_on_empty = false
        placeholder_text = <span foreground="##$textAlpha"><i>󰌾 Logged in as </i><span foreground="##$accentAlpha">$USER</span></span>
        hide_input = false
        check_color = $accent
        fail_color = $red
        fail_text = <i>$FAIL <b>($ATTEMPTS)</b></i>
        capslock_color = $yellow
        position = 0, -47
        halign = center
        valign = center
      }
    '';

    "hypr/gamemode.sh" = {
      text = ''
        #!/usr/bin/env sh
        HYPRGAMEMODE=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')
        if [ "$HYPRGAMEMODE" = 1 ] ; then
            hyprctl --batch "\
                keyword animations:enabled 0;\
                keyword decoration:shadow:enabled 0;\
                keyword decoration:blur:enabled 0;\
                keyword general:allow_tearing 1;\
                keyword general:gaps_in 0;\
                keyword general:gaps_out 0;\
                keyword general:border_size 1;\
                keyword decoration:rounding 0"
            exit
        fi
        hyprctl reload
      '';
      executable = true;
    };
  };
}
