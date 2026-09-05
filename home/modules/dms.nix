{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  profileImage = "%h/Pictures/avatar.jpg";
  c = config.lib.stylix.colors;
  # DMS's stock Stylix mapping uses base04 for secondary text. With this light
  # palette that is too close to the notification card background, so use the
  # normal foreground for both primary and secondary surface text.
  dmsHighContrastTheme = pkgs.writeText "dms-stylix-high-contrast.json" (builtins.toJSON {
    dark = {
      name = "Stylix High Contrast";
      background = "#${c.base00}";
      backgroundText = "#${c.base05}";
      surface = "#${c.base01}";
      surfaceContainer = "#${c.base01}";
      surfaceContainerHigh = "#${c.base02}";
      surfaceContainerHighest = "#${c.base03}";
      surfaceVariant = "#${c.base02}";
      surfaceText = "#${c.base05}";
      surfaceVariantText = "#${c.base05}";
      outline = "#${c.base03}";
      primary = "#${c.base0D}";
      primaryText = "#${c.base00}";
      primaryContainer = "#${c.base0C}";
      secondary = "#${c.base0E}";
      error = "#${c.base08}";
      warning = "#${c.base0A}";
      info = "#${c.base0C}";
      surfaceTint = "#${c.base0D}";
    };
    light = {
      name = "Stylix High Contrast";
      background = "#${c.base00}";
      backgroundText = "#${c.base05}";
      surface = "#${c.base01}";
      surfaceContainer = "#${c.base01}";
      surfaceContainerHigh = "#${c.base02}";
      surfaceContainerHighest = "#${c.base03}";
      surfaceVariant = "#${c.base02}";
      surfaceText = "#${c.base05}";
      surfaceVariantText = "#${c.base05}";
      outline = "#${c.base03}";
      primary = "#${c.base0D}";
      primaryText = "#${c.base00}";
      primaryContainer = "#${c.base0C}";
      secondary = "#${c.base0E}";
      error = "#${c.base08}";
      warning = "#${c.base0A}";
      info = "#${c.base0C}";
      surfaceTint = "#${c.base0D}";
    };
  });
  setDmsProfileImage = pkgs.writeShellScript "set-dms-profile-image" ''
    image_path="$1"
    for attempt in $(${pkgs.coreutils}/bin/seq 1 40); do
      if ${lib.getExe config.programs.dank-material-shell.package} ipc call profile setImage "$image_path" \
        | ${pkgs.gnugrep}/bin/grep -q '^SUCCESS'; then
        exit 0
      fi
      ${pkgs.coreutils}/bin/sleep 0.25
    done
    exit 1
  '';
in
{
  programs.dank-material-shell = {
    enable = true;

    # DMS currently exposes font scaling but not popout geometry. Enlarge the
    # real Wayland surface first, then scale its loader into that allocation.
    # Doing this in the shared backend avoids clipping individual popouts.
    package = inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        substituteInPlace $out/share/quickshell/dms/Widgets/DankPopout.qml \
          --replace-fail 'it.popupWidth = Qt.binding(() => root.popupWidth);' 'it.popupWidth = Qt.binding(() => root.popupWidth * 1.125);' \
          --replace-fail 'it.popupHeight = Qt.binding(() => root.popupHeight);' 'it.popupHeight = Qt.binding(() => root.popupHeight * 1.125);'
        chmod u+w $out/share/quickshell/dms/Widgets
        for backend in DankPopoutStandalone.qml DankPopoutConnected.qml; do
          sed -i '/id: contentLoader/{n;s|anchors.fill: parent|anchors.left: parent.left\n                            anchors.top: parent.top\n                            width: parent.width / 1.125\n                            height: parent.height / 1.125\n                            scale: 1.125\n                            transformOrigin: Item.TopLeft|;}' \
            "$out/share/quickshell/dms/Widgets/$backend"
        done
      '';
    });

    systemd = {
      enable = true;
      restartIfChanged = true;
    };

    enableCalendarEvents = true;
    enableDynamicTheming = true;
    enableVPN = true;

    plugins.titleMedia = {
      enable = true;
      src = ./dms-plugins/title-media;
      settings.managed = true;
    };
    plugins.menuClock = {
      enable = true;
      src = ./dms-plugins/menu-clock;
      settings.managed = true;
    };
    plugins.languageLabel = {
      enable = true;
      src = ./dms-plugins/language-label;
      settings.managed = true;
    };

    # GNOME Night Light-style automatic sunset/sunrise scheduling. DMS owns
    # gamma control, so Gammastep is intentionally not started alongside it.
    session = {
      nightModeEnabled = true;
      nightModeTemperature = 4500;
      nightModeHighTemperature = 6500;
      nightModeAutoEnabled = true;
      nightModeAutoMode = "location";
      nightModeUseIPLocation = true;
    };

    # Keep application theming under Stylix. DMS still controls its own light
    # and dark appearance without overwriting the declarative GTK/Qt themes.
    settings = {
      # Match the compact macOS menu-bar presentation.
      clockFormat = "24h";
      showSeconds = false;
      padHours12Hour = false;
      clockDateFormat = "ddd MMM d";
      fontFamily = lib.mkForce "SF Compact Rounded";
      fontWeight = 500;
      # Popouts do not inherit the per-bar scale. Give control center and
      # notification surfaces a modest typography bump for the 4K display.
      fontScale = 1.25;
      customThemeFile = lib.mkForce dmsHighContrastTheme;

      # Prefer restrained desktop motion over the stock Material treatment.
      animationVariant = 1;
      animationSpeed = 1;
      popoutAnimationSpeed = 1;
      modalAnimationSpeed = 1;
      notificationAnimationSpeed = 1;
      reduceMotion = false;
      enableRippleEffects = false;
      springBounce = 0;
      audioVisualizerEnabled = false;
      systemTrayIconTintMode = "primary";
      soundNewNotification = false;

      # Keep every shell surface flat and opaque. Hyprland owns the only
      # remaining animations: windows and workspaces.
      blurEnabled = false;
      m3ElevationEnabled = false;
      modalElevationEnabled = false;
      popoutElevationEnabled = false;
      barElevationEnabled = false;

      # DMS only exposes fixed OSD anchors; top-center places it just below the
      # bar instead of at the bottom edge.
      osdPosition = 4;

      gtkThemingEnabled = false;
      qtThemingEnabled = false;
      syncModeWithPortal = true;

      showWorkspaceIndex = true;
      showWorkspaceName = false;
      showWorkspaceApps = false;
      showOccupiedWorkspacesOnly = false;
      workspaceScrolling = true;

      # The media widget uses the wheel for previous/next instead of changing
      # an individual player's volume.
      audioScrollMode = "song";

      notificationHistoryEnabled = true;
      notificationHistoryMaxCount = 100;
      notificationHistoryMaxAgeDays = 14;
      notificationSummaryFontSize = 18;
      notificationBodyFontSize = 16;

      controlCenterShowNetworkIcon = true;
      controlCenterShowBluetoothIcon = true;
      controlCenterShowAudioIcon = true;
      controlCenterShowAudioPercent = false;
      controlCenterShowBrightnessIcon = true;
      controlCenterShowBrightnessPercent = false;
      controlCenterShowMicIcon = false;
      controlCenterShowBatteryIcon = false;
      controlCenterShowPrinterIcon = false;

      controlCenterWidgets = [
        {
          id = "volumeSlider";
          enabled = true;
          width = 50;
        }
        {
          id = "brightnessSlider";
          enabled = true;
          width = 50;
        }
        {
          id = "wifi";
          enabled = true;
          width = 50;
        }
        {
          id = "bluetooth";
          enabled = true;
          width = 50;
        }
        {
          id = "builtin_vpn";
          enabled = true;
          width = 50;
        }
        {
          id = "audioOutput";
          enabled = true;
          width = 50;
        }
        {
          id = "audioInput";
          enabled = true;
          width = 50;
        }
        {
          id = "doNotDisturb";
          enabled = true;
          width = 50;
        }
        {
          id = "idleInhibitor";
          enabled = true;
          width = 50;
        }
        {
          id = "nightMode";
          enabled = true;
          width = 50;
        }
      ];

      barConfigs = [
        {
          id = "main";
          name = "Main Bar";
          enabled = true;
          position = 0;
          screenPreferences = [ "all" ];
          showOnLastDisplay = true;

          leftWidgets = [
            {
              id = "workspaceSwitcher";
              enabled = true;
            }
          ];
          centerWidgets = [
            {
              id = "titleMedia";
              enabled = true;
            }
          ];
          rightWidgets = [
            {
              id = "systemTray";
              enabled = true;
            }
            {
              id = "languageLabel";
              enabled = true;
            }
            {
              id = "controlCenterButton";
              enabled = true;
              showNetworkIcon = true;
              showBluetoothIcon = true;
              showAudioIcon = true;
              showAudioPercent = false;
              showBrightnessIcon = true;
              showBrightnessPercent = false;
              showMicIcon = false;
              showBatteryIcon = false;
              showPrinterIcon = false;
              showScreenSharingIcon = true;
            }
            {
              id = "menuClock";
              enabled = true;
            }
          ];

          spacing = 8;
          innerPadding = 14;
          bottomGap = 10;
          transparency = 1.0;
          widgetTransparency = 1.0;
          noBackground = true;
          borderEnabled = false;
          widgetOutlineEnabled = false;
          widgetPadding = 10;
          # Combined with the global 1.15 scale this keeps existing stock bar
          # text at approximately its previous size.
          fontScale = 1.07;
          iconScale = 1.3;
          autoHide = false;
          visible = true;
          popupGapsAuto = true;
          shadowIntensity = 0;
        }
      ];
    };
  };

  systemd.user.services.dms-profile-image = {
    Unit = {
      Description = "Set the DankMaterialShell profile image";
      After = [ "dms.service" ];
      Requires = [ "dms.service" ];
      ConditionPathExists = profileImage;
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${setDmsProfileImage} ${profileImage}";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
