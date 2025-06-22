{
  services.plex = {
    enable = true;
    openFirewall = true;
    user = "paranas";
    group = "paranas";
    dataDir = "/mnt/media/plexbak";
  };
}
