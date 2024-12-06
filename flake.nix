{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fufexan-dotfiles = {
      url = "github:fufexan/dotfiles";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser.url = "github:MarceColl/zen-browser-flake";

    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";

    catppuccin.url = "github:catppuccin/nix";

    minimal-tmux = {
      url = "github:niksingh710/minimal-tmux-status";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations = {
      default = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/default/configuration.nix
          inputs.home-manager.nixosModules.default
        ];
      };
    };

    homeConfigurations."taha@nixos" =
      inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;

        modules = [
          inputs.hyprland.homeManagerModules.default
          { wayland.windowManager.hyprland.enable = true; }
          inputs.catppuccin.homeManagerModules.catppuccin
        ];
      };
  };
}