# Preferences observed on taha-mac on 2026-09-16. Omitted keys were not explicitly set.
{ pkgs, ... }:
{
  system.defaults = {
    NSGlobalDomain = {
      "AppleEnableSwipeNavigateWithScrolls" = true;
      "AppleInterfaceStyleSwitchesAutomatically" = true;
      "AppleKeyboardUIMode" = 2;
      "ApplePressAndHoldEnabled" = false;
      "AppleShowScrollBars" = "Automatic";
      "AppleScrollerPagingBehavior" = true;
      "NSAutomaticCapitalizationEnabled" = true;
      "NSAutomaticDashSubstitutionEnabled" = true;
      "NSAutomaticPeriodSubstitutionEnabled" = false;
      "NSAutomaticQuoteSubstitutionEnabled" = true;
      "NSAutomaticSpellingCorrectionEnabled" = false;
      "NSTableViewDefaultSizeMode" = 2;
      "InitialKeyRepeat" = 15;
      "KeyRepeat" = 2;
      "com.apple.keyboard.fnState" = false;
      "com.apple.sound.beep.volume" = 1.0;
      "com.apple.sound.beep.feedback" = 0;
      "com.apple.trackpad.scaling" = 0.875;
      "com.apple.trackpad.forceClick" = true;
      "com.apple.springing.enabled" = true;
      "com.apple.springing.delay" = 0.5;
      "AppleMeasurementUnits" = "Inches";
      "AppleMetricUnits" = 0;
      "AppleTemperatureUnit" = "Celsius";
      "AppleICUForce24HourTime" = true;
      "_HIHideMenuBar" = false;
      "AppleReduceDesktopTinting" = false;
    };
    dock = {
      "autohide" = true;
      "autohide-delay" = 0.0;
      # AeroSpace's off-screen workspace windows otherwise confuse Mission Control.
      "expose-group-apps" = true;
      "mru-spaces" = false;
      "showAppExposeGestureEnabled" = true;
      "show-recents" = false;
      "tilesize" = 90;
      "largesize" = 128;
      "wvous-tr-corner" = 2;
      "wvous-br-corner" = 14;
      "persistent-apps" = [
        "/Applications/Firefox Developer Edition.app"
        "/Applications/Ghostty.app"
        "/Applications/Mattermost.app"
        "${pkgs.obsidian}/Applications/Obsidian.app"
        "/Applications/Feishin.app"
      ];
    };
    finder = {
      "FXPreferredViewStyle" = "Nlsv";
      "QuitMenuItem" = true;
      "ShowExternalHardDrivesOnDesktop" = true;
      "ShowHardDrivesOnDesktop" = false;
      "ShowRemovableMediaOnDesktop" = true;
      "_FXShowPosixPathInTitle" = true;
      "NewWindowTarget" = "Recents";
    };
    trackpad = {
      "Clicking" = false;
      "Dragging" = false;
      "TrackpadRightClick" = true;
      "TrackpadThreeFingerDrag" = false;
      "ActuationStrength" = 0;
      "FirstClickThreshold" = 0;
      "SecondClickThreshold" = 0;
      "TrackpadThreeFingerTapGesture" = 0;
      "ActuateDetents" = true;
      "DragLock" = false;
      "ForceSuppressed" = false;
      "TrackpadCornerSecondaryClick" = 0;
      "TrackpadFourFingerHorizSwipeGesture" = 2;
      "TrackpadFourFingerPinchGesture" = 2;
      "TrackpadFourFingerVertSwipeGesture" = 2;
      "TrackpadMomentumScroll" = true;
      "TrackpadPinch" = true;
      "TrackpadRotate" = true;
      "TrackpadThreeFingerHorizSwipeGesture" = 2;
      "TrackpadThreeFingerVertSwipeGesture" = 2;
      "TrackpadTwoFingerDoubleTapGesture" = true;
      "TrackpadTwoFingerFromRightEdgeSwipeGesture" = 3;
    };
    menuExtraClock = {
      "FlashDateSeparators" = false;
      "IsAnalog" = false;
      "ShowSeconds" = true;
    };
    WindowManager = {
      "GloballyEnabled" = false;
      "AutoHide" = false;
      "AppWindowGroupingBehavior" = true;
      "HideDesktop" = true;
      "StandardHideWidgets" = false;
      "StageManagerHideWidgets" = false;
    };
    CustomUserPreferences = {
      "NSGlobalDomain" = {
        "AppleHighlightColor" = "0.000000 0.881808 0.859224 Other";
        "AppleLanguages" = [
          "en-US"
          "fa-US"
        ];
        "AppleLocale" = "en_US";
        "com.apple.mouse.linear" = true;
      };
      "com.apple.HIToolbox" = {
        "AppleEnabledInputSources" = [
          {
            "InputSourceKind" = "Keyboard Layout";
            "KeyboardLayout ID" = 0;
            "KeyboardLayout Name" = "U.S.";
          }
          {
            "Bundle ID" = "com.apple.CharacterPaletteIM";
            "InputSourceKind" = "Non Keyboard Input Method";
          }
          {
            "Bundle ID" = "com.apple.PressAndHold";
            "InputSourceKind" = "Non Keyboard Input Method";
          }
          {
            "InputSourceKind" = "Keyboard Layout";
            "KeyboardLayout ID" = -2901;
            "KeyboardLayout Name" = "Persian-ISIRI 2901";
          }
          {
            "Bundle ID" = "com.apple.inputmethod.EmojiFunctionRowItem";
            "InputSourceKind" = "Non Keyboard Input Method";
          }
        ];
      };
    };
  };
}
