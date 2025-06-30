# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, inputs, ... }:
let
  tuigreet = "${pkgs.greetd.tuigreet}/bin/tuigreet";
  hyprland-session = "${pkgs.hyprland}/share/wayland-sessions";
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.default
  ];

  # NTFS
  boot.supportedFilesystems = [ "ntfs" ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # AMD
  boot.initrd.kernelModules = [ "amdgpu" ];
  systemd.tmpfiles.rules =
    [ "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}" ];

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nix.settings.trusted-users = [ "root" "taha" ];

  # Enable networking
  networking.networkmanager.enable = true;
  networking.nameservers = [ "192.168.1.1" ];
  networking.firewall.allowedTCPPorts = [ 5173 8040 10810 ];

  services.resolved = {
    enable = true;
    dnssec = "false";
    domains = [ "~." ];
    fallbackDns = [ "1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one" ];
    dnsovertls = "false";
  };

  # Set your time zone.
  time.timeZone = "Asia/Tehran";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];
  };

  services = {
    xserver.enable = false; # disable xorg server
    # https://wiki.archlinux.org/title/Greetd
    greetd = {
      enable = true;
      settings = {
        default_session = {
          user = "taha";
          # command = "$HOME/.wayland-session"; # start a wayland session directly without a login manager
          command =
            "${tuigreet} --time --remember --remember-session --sessions ${hyprland-session} --cmd 'Hyprland && waybar'";
        };
      };
    };
  };

  systemd.user.services.mpris-proxy = {
    description = "Mpris proxy";
    after = [ "network.target" "sound.target" ];
    wantedBy = [ "default.target" ];
    serviceConfig.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
  };

  security.polkit.enable = true;
  security.pam.services.hyprlock = { };

  services.blueman.enable = true;
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [ rocmPackages.clr.icd ];
    };
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Experimental = true;
          ClassicBoundedOnly = true;
          UserspaceHID = false;
        };
      };
    };
    i2c.enable = true;
  };

  services.libinput.enable = true;
  services.touchegg.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.taha = {
    isNormalUser = true;
    description = "Taha";
    extraGroups = [ "networkmanager" "wheel" "docker" "input" "i2c" ];
    packages = [ ];
  };

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  virtualisation.containers.enable = true;

  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    ungoogled-chromium
    inputs.zen-browser.packages."${system}".default
    telegram-desktop
    discord
    plexamp
    pavucontrol
    thunderbird
    nicotine-plus
    spek
    ghostty
    nautilus
    haruna
    qalculate-gtk
    libreoffice

    docker
    nodejs_22
    deno
    bun
    python311
    python311Packages.pip
    vim
    kitty
    tmux
    teamocil
    nil
    cargo
    nixfmt-classic
    lazygit
    lazydocker
    delta
    stylua
    nixfmt-rfc-style
    tailwindcss-language-server
    ngrok
    cloudflared
    prettierd
    eslint_d

    openvpn
    xray
    tinyproxy
    proxychains

    wget
    eza
    git
    gnupg
    fuzzel
    fd
    ripgrep
    gotop
    neofetch
    bat
    unzip
    unrar
    playerctl
    waybar-mpris
    btop
    nvtopPackages.amd
    clipse
    openssl
    hyprpaper
    hyprshot
    hyprpicker
    hypridle
    hyprlock
    mkcert
    wl-clipboard
    wl-screenrec
    slurp
    ncdu
    fzf
    tree-sitter
    imagemagick
    ffmpeg

    protonup
    mangohud
    vulkan-tools
    lact
    gamescope
    gamescope-wsi

    ddcui
    ddcutil

    pipewire
    pamixer
    wireplumber
    swaynotificationcenter
    libsForQt5.qt5.qtwayland
    gcc
    libgcc
    gnumake
    nix-prefetch-github
    ntfs3g
    libinput
    libinput-gestures
    libnotify
    libqalculate
  ];

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "taha" ];
  };
  environment.etc = {
    "1password/custom_allowed_browsers" = {
      text = ''
        .zen-wrapped
        zen
        zen-bin
        zen-beta-bin
      '';
      mode = "0755";
    };
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    protontricks = {
      enable = true;
      package = pkgs.protontricks;
    };
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };
  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS =
      "/home/taha/.steam/root/compatibilitytools.d";
  };
  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        softrealtime = "auto";
        inhibit_screensaver = 1;
        renice = 15;
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device =
          1; # The DRM device number on the system (usually 0), ie. the number in /sys/class/drm/card0/
        amd_performance_level = "high";
      };
      custom = {
        start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
        end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
      };
    };
  };
  systemd.services.lact = {
    description = "AMDGPU Control Daemon";
    after = [ "multi-user.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = { ExecStart = "${pkgs.lact}/bin/lact daemon"; };
    enable = true;
  };

  fonts.packages = with pkgs; [
    nerd-fonts.caskaydia-cove
    nerd-fonts.space-mono
    nerd-fonts.fantasque-sans-mono
  ];

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "24.11";

  programs.hyprland.enable = true;
}
