# Inspired by https://github.com/AlexNabokikh/nix-config

{
  description = "NixOS and nix-darwin configs for my machines";
  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixOS profiles to optimize settings for different hardware
    hardware.url = "github:nixos/nixos-hardware";

    # Nix Darwin (for MacOS machines)
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Homebrew
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    minimal-tmux = {
      url = "github:niksingh710/minimal-tmux-status";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      # pinning back to fca03f1 because of overlay issue https://github.com/nix-community/stylix/issues/2323#issuecomment-4529576643
      url = "github:nix-community/nixvim/fca03f175902fe899a87872228bf69c1b43a8543";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    apple-fonts.url = "github:Lyndeno/apple-fonts.nix";

    nixcord.url = "github:kaylorben/nixcord";

    vicinae = {
      url = "github:vicinaehq/vicinae";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vicinae-extensions = {
      url = "github:vicinaehq/extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    headscale.url = "github:juanfont/headscale";
  };

  outputs =
    {
      self,
      darwin,
      home-manager,
      nix-homebrew,
      nixpkgs,
      ...
    }@inputs:
    let
      inherit (self) outputs;

      # Define user configurations
      users = {
        taha = {
          email = "paramoNNN@proton.me";
          fullName = "Taha";
          gitSigningKeys = {
            taha-pc = "FCF819681F9DD20E";
            taha-mac = "A546293786574A84";
          };
          name = "taha";
        };
        paranas = {
          email = "paramoNNN@proton.me";
          fullName = "Taha";
          gitSigningKeys.paranas = "FCF819681F9DD20E";
          name = "paranas";
        };
      };

      # Function for NixOS system configuration
      mkNixosConfiguration =
        hostname: username:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs outputs hostname;
            userConfig = users.${username};
          };
          modules = [ ./hosts/${hostname}/configuration.nix ];
        };

      # Function for nix-darwin system configuration
      mkDarwinConfiguration =
        hostname: username:
        darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = {
            inherit inputs outputs hostname;
            userConfig = users.${username};
          };
          modules = [
            ./hosts/${hostname}/configuration.nix
            home-manager.darwinModules.home-manager
            nix-homebrew.darwinModules.nix-homebrew
          ];
        };

      # Function for Home Manager configuration
      mkHomeConfiguration =
        system: username: hostname:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs { inherit system; };
          extraSpecialArgs = {
            inherit inputs outputs hostname;
            userConfig = users.${username};
          };
          modules = [
            inputs.stylix.homeModules.stylix
            inputs.vicinae.homeManagerModules.default
            ./home/${username}/${hostname}.nix
          ];
        };
    in
    {
      nixosConfigurations = {
        taha = mkNixosConfiguration "taha-pc" "taha";
        paranas = mkNixosConfiguration "paranas" "paranas";
      };

      darwinConfigurations = {
        "taha-mac" = mkDarwinConfiguration "taha-mac" "taha";
      };

      homeConfigurations = {
        "taha@taha-mac" = mkHomeConfiguration "aarch64-darwin" "taha" "taha-mac";
        "taha@taha-pc" = mkHomeConfiguration "x86_64-linux" "taha" "taha-pc";
        "paranas@paranas" = mkHomeConfiguration "x86_64-linux" "paranas" "paranas";
      };

      overlays = import ./overlays { inherit inputs; };
    };
}
