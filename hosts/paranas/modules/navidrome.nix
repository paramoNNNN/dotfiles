{
  services.navidrome = {
    enable = true;
    settings = {
      Plugins.Enabled = true;
      Plugins.AutoReload = true;
      Plugins.LogLevel = "debug";

      EnableSharing = true;
      CoverArtQuality = 100;

      Agents = "lastfm,listenbrainz";
      LastFM.ScrobbleFirstArtistOnly = true;

      Prometheus.Enabled = true;
      Prometheus.MetricsPath = "/metrics_navi";
    };
  };
  systemd.services.navidrome.serviceConfig = {
    EnvironmentFile = "/var/lib/navidrome-secrets/environment";
    BindReadOnlyPaths = [
      "/storage/media/Music"
      "/storage/media/Navidrome/Plugins"
    ];
  };

  systemd.tmpfiles.rules = [ "d /var/lib/navidrome-secrets 0750 root navidrome -" ];
}
