{ pkgs, ... }: {
  dconf = {
    enable = true;
    settings = {
      "org/gnome/mutter" = {
        experimental-features = [ "scale-monitor-framebuffer" ];
      };
      "org/gnome/shell" = {
        enabled-extensions = [
          pkgs.gnomeExtensions.appindicator.extensionUuid
          pkgs.gnomeExtensions.just-perfection.extensionUuid
          pkgs.gnomeExtensions.media-controls.extensionUuid
          pkgs.gnomeExtensions.blur-my-shell.extensionUuid
          pkgs.gnomeExtensions.dash-to-dock.extensionUuid
          pkgs.gnomeExtensions.vertical-workspaces.extensionUuid
          pkgs.gnomeExtensions.vicinae.extensionUuid
          pkgs.gnomeExtensions.brightness-control-using-ddcutil.extensionUuid
        ];
      };
    };
  };
}
