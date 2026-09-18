{
  pkgs,
  outputs,
  inputs,
  hostname,
  userConfig,
  ...
}:
{
  imports = [
    ./defaults.nix
    ./homebrew.nix
  ];
  system.primaryUser = userConfig.name;
  networking.computerName = "Taha’s MacBook Pro";
  networking.localHostName = "Tahas-MacBook-Pro-4";
  time.timeZone = "Asia/Tehran";

  home-manager = {
    backupFileExtension = "before-nix";
    extraSpecialArgs = {
      inherit
        inputs
        outputs
        hostname
        userConfig
        ;
    };
    users.${userConfig.name}.imports = [
      inputs.stylix.homeModules.stylix
      ../../home/taha/taha-mac.nix
    ];
  };

  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = "${userConfig.name}";
    autoMigrate = true;
  };

  nixpkgs = {
    overlays = [ outputs.overlays.stable-packages ];

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

  nix.gc = {
    automatic = true;
    interval = {
      Weekday = 0;
      Hour = 0;
      Minute = 0;
    };
    options = "--delete-older-than 7d";
  };

  users.users.${userConfig.name} = {
    name = "${userConfig.name}";
    home = "/Users/${userConfig.name}";
  };

  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  environment.systemPackages = with pkgs; [
    aria2
    gh
    glab
    hyperfine
    ncdu
    tree
    wget

    bashInteractive
    bitwarden-cli
    cmake
    gcc16
    gnupg
    gping
    mkcert
    nodejs_26
    openvpn
    pinentry_mac
    proxychains-ng
    python312
    socat
    wakeonlan

    bat
    delta
    eza
    fd
    jq
    lazydocker
    lazygit
    ripgrep
    teamocil
    xray
    nix-prefetch-github
    bun
    platformio
    nixfmt
    monitorcontrol

    codex
    codex-acp
  ];

  programs.ssh = {
    extraConfig = ''
      ServerAliveInterval 15
      ServerAliveCountMax 200
    '';
  };

  programs.zsh.enable = true;
  programs.fish.enable = true;

  fonts.packages = with pkgs; [
    nerd-fonts.caskaydia-cove
    nerd-fonts.space-mono
  ];

  # Used for backwards compatibility, please read the changelog before changing.
  system.stateVersion = 5;
}
