{
  inputs,
  pkgs,
  lib,
  ...
}:
{
  programs.vicinae = {
    enable = true;
    systemd = {
      enable = true;
      autoStart = true;
      environment = {
        QT_SCALE_FACTOR = 1.25;
      };
    };
    settings = {
      close_on_focus_loss = true;
      font = {
        normal = lib.mkForce {
          size = 11;
          family = "SF Compact Rounded";
        };
      };
      launcher_window = lib.mkForce { opacity = 1; };
    };
    extensions = with inputs.vicinae-extensions.packages.${pkgs.stdenv.hostPlatform.system}; [
      nix
      hypr-keybinds
      gnome-dnd
    ];
  };
}
