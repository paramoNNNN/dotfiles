{ inputs, pkgs, lib, ... }: {
  services.vicinae = {
    enable = true;
    systemd = {
      enable = true;
      autoStart = true;
      environment = { QT_SCALE_FACTOR = 1.25; };
    };
    settings = {
      close_on_focus_loss = true;
      font = { normal = { size = 11; }; };
      launcher_window = lib.mkForce { opacity = 0.95; };
    };
    extensions =
      with inputs.vicinae-extensions.packages.${pkgs.stdenv.hostPlatform.system}; [
        bluetooth
        nix
        hypr-keybinds
        gnome-dnd
      ];
  };
}
