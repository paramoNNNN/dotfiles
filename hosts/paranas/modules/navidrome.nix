{ lib, pkgs, ... }:

let
  audiomuseaiV10 = pkgs.stdenvNoCC.mkDerivation {
    pname = "audiomuseai";
    version = "10";

    src = pkgs.fetchurl {
      url = "https://github.com/NeptuneHub/AudioMuse-AI-NV-plugin/releases/download/v10/audiomuseai.ndp";
      hash = "sha256-wTjprxbwl9jNB6yVf7iknZGn2gZuW0oUV8rb1HmqEKc=";
    };

    dontUnpack = true;
    installPhase = ''
      runHook preInstall
      install -Dm444 "$src" "$out/share/plugins/audiomuseai.ndp"
      runHook postInstall
    '';

    passthru.isNavidromePlugin = true;

    meta = {
      description = "AudioMuse-AI integration plugin for Navidrome";
      homepage = "https://github.com/NeptuneHub/AudioMuse-AI-NV-plugin";
      license = lib.licenses.agpl3Only;
      sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    };
  };
in
{
  services.navidrome = {
    enable = true;
    withPlugins = p: [
      p.apple-music
      audiomuseaiV10
    ];
    settings = {
      Address = "0.0.0.0";
      Plugins.Enabled = true;
      Plugins.AutoReload = true;
      Plugins.LogLevel = "debug";

      EnableExternalServices = true;
      EnableSharing = true;
      CoverArtQuality = 100;

      Agents = "audiomuseai,apple-music,lastfm,listenbrainz";
      LastFM.ScrobbleFirstArtistOnly = true;

      Prometheus.Enabled = true;
      Prometheus.MetricsPath = "/metrics_navi";
    };
  };
  networking.firewall.allowedTCPPorts = [ 4533 ];
  systemd.services.navidrome.serviceConfig = {
    EnvironmentFile = "/var/lib/navidrome-secrets/environment";
    BindReadOnlyPaths = [
      "/storage/media/Music"
    ];
  };

  systemd.tmpfiles.rules = [ "d /var/lib/navidrome-secrets 0750 root navidrome -" ];
}
