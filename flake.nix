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
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser.url = "github:0xc000022070/zen-browser-flake";

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    apple-fonts.url = "github:Lyndeno/apple-fonts.nix";
    apple-emoji = {
      url = "github:samuelngs/apple-emoji-linux";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nextmeeting = {
      url = "github:chmouel/nextmeeting?dir=packaging";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, darwin, home-manager, nix-homebrew, nixpkgs, ... }@inputs:
    let
      inherit (self) outputs;

      # Define user configurations
      users = {
        taha = {
          email = "taha.ojari@gmail.com";
          fullName = "Taha Ojari";
          gitKey = "asd";
          name = "taha";
        };
        paranas = {
          email = "paramonnnnnn@gmail.com";
          fullName = "Taha Ojari";
          gitKey = "asd";
          name = "paranas";
        };
      };

      # Function for NixOS system configuration
      mkNixosConfiguration = hostname: username:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs outputs hostname;
            userConfig = users.${username};
          };
          modules = [ ./hosts/${hostname}/configuration.nix ];
        };

      # Function for nix-darwin system configuration
      mkDarwinConfiguration = hostname: username:
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
      mkHomeConfiguration = system: username: hostname:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs { inherit system; };
          extraSpecialArgs = {
            inherit inputs outputs;
            userConfig = users.${username};
          };
          modules = [
            inputs.stylix.homeModules.stylix
            ./home/${username}/${hostname}.nix
          ];
        };
    in {
      nixosConfigurations = {
        taha = mkNixosConfiguration "taha-pc" "taha";
        paranas = mkNixosConfiguration "paranas" "paranas";
      };

      darwinConfigurations = {
        "taha-mac" = mkDarwinConfiguration "taha-mac" "taha";
      };

      homeConfigurations = {
        "taha@taha-mac" =
          mkHomeConfiguration "aarch64-darwin" "taha" "taha-mac";
        "taha@taha-pc" = mkHomeConfiguration "x86_64-linux" "taha" "taha-pc";
        "paranas@paranas" =
          mkHomeConfiguration "x86_64-linux" "paranas" "paranas";
      };

      overlays = import ./overlays { inherit inputs; };
    };
}
