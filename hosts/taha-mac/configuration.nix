{ pkgs
, outputs
, userConfig
, ...
}: {
  # Add nix-homebrew configuration
  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = "${userConfig.name}";
    autoMigrate = true;
  };

  # Nixpkgs configuration
  nixpkgs = {
    overlays = [
      outputs.overlays.stable-packages
    ];

    config = {
      allowUnfree = true;
    };
  };

  # Nix settings
  nix.settings = {
    experimental-features = "nix-command flakes";
  };
  nix.optimise.automatic = true;

  nix.package = pkgs.nix;

  # Enable Nix daemon
  services.nix-daemon.enable = true;

  # User configuration
  users.users.${userConfig.name} = {
    name = "${userConfig.name}";
    home = "/Users/${userConfig.name}";
  };

  # Add ability to use TouchID for sudo
  security.pam.enableSudoTouchIdAuth = true;

  # System settings
  # system = {
  #   defaults = {
  #     NSGlobalDomain = ;
  #     LaunchServices = {
  #       LSQuarantine = false;
  #     };
  #     trackpad = {
  #       TrackpadRightClick = true;
  #       TrackpadThreeFingerDrag = true;
  #       Clicking = true;
  #     };
  #     finder = {
  #       AppleShowAllFiles = true;
  #       CreateDesktop = false;
  #       FXDefaultSearchScope = "SCcf";
  #       FXEnableExtensionChangeWarning = false;
  #       FXPreferredViewStyle = "Nlsv";
  #       QuitMenuItem = true;
  #       ShowPathbar = true;
  #       ShowStatusBar = true;
  #       _FXShowPosixPathInTitle = true;
  #       _FXSortFoldersFirst = true;
  #     };
  #     dock = {
  #       autohide = true;
  #       expose-animation-duration = 0.15;
  #       show-recents = false;
  #       showhidden = true;
  #       persistent-apps = [
  #         "/Applications/Brave Browser.app"
  #         "${pkgs.alacritty}/Applications/Alacritty.app"
  #         "${pkgs.telegram-desktop}/Applications/Telegram.app"
  #       ];
  #       tilesize = 30;
  #       wvous-bl-corner = 1;
  #       wvous-br-corner = 1;
  #       wvous-tl-corner = 1;
  #       wvous-tr-corner = 1;
  #     };
  #     screencapture = {
  #       location = "/Users/${userConfig.name}/Downloads/temp";
  #       type = "png";
  #       disable-shadow = true;
  #     };
  #   };
  #   keyboard = {
  #     enableKeyMapping = true;
  #     # swapLeftCtrlAndFn = true;
  #     # Remap §± to ~
  #     userKeyMapping = [
  #       {
  #         HIDKeyboardModifierMappingDst = 30064771125;
  #         HIDKeyboardModifierMappingSrc = 30064771172;
  #       }
  #     ];
  #   };
  # };

  # System packages
  environment.systemPackages = with pkgs; [
    bat
    delta
    eza
    fd
    jq
    lazydocker
    lazygit
    ripgrep
    teamocil
  ];

  # Shell configuration
  programs.zsh.enable = true;
  programs.fish.enable = true;

  # Fonts configuration
  fonts.packages = with pkgs; [
    nerd-fonts.caskaydia-cove
    nerd-fonts.space-mono
  ];

  homebrew = {
    enable = true;
    casks = [
      "dozer"
      "raycast"
    ];
  };

  # Used for backwards compatibility, please read the changelog before changing.
  system.stateVersion = 5;
}
