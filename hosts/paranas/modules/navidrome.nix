{ pkgs, ... }:

{
  services.navidrome = {
    enable = true;
    plugins = with pkgs.navidromePlugins; [
      apple-music
      audiomuseai
    ];
    settings = {
      Plugins.Enabled = true;
      Plugins.AutoReload = true;
      Plugins.LogLevel = "debug";

      EnableExternalServices = true;
      EnableSharing = true;
      CoverArtQuality = 100;

      Agents = "audiomuseai,lastfm,listenbrainz";
      LastFM.ScrobbleFirstArtistOnly = true;

      Prometheus.Enabled = true;
      Prometheus.MetricsPath = "/metrics_navi";
    };
  };
  systemd.services.navidrome.serviceConfig = {
    EnvironmentFile = "/var/lib/navidrome-secrets/environment";
    BindReadOnlyPaths = [
      "/storage/media/Music"
    ];
  };

  systemd.tmpfiles.rules = [ "d /var/lib/navidrome-secrets 0750 root navidrome -" ];
}
