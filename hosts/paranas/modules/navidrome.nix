{
  services.navidrome = {
    enable = true;
    settings = {
      Plugins.Folder = "/storage/media/Navidrome/Plugins";
      Plugins.LogLevel = "debug";

      EnableSharing = true;
      CoverArtQuality = 100;

      Agents = "lastfm,listenbrainz";
      LastFM.ApiKey = "";
      LastFM.Secret = "";
    };
  };
  systemd.services.navidrome.serviceConfig = {
    BindReadOnlyPaths = [
      "/storage/media/Music"
      "/storage/media/Navidrome/Plugins"
    ];
  };
}
