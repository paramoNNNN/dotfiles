{ ... }: {
  # Install cliphist via home-manager module
  services.cliphist = {
    enable = true;
    systemdTargets = "hyprland-session.target";
    allowImages = true;
  };
  xdg.configFile = { "cliphist/fuzzel.sh" = { source = ./fuzzel-img.sh; }; };
}
