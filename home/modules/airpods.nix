{ lib, pkgs, ... }:
let
  airpods = pkgs.callPackage (
    {
      lib,
      rustPlatform,
      fetchFromGitHub,
      pkg-config,
      dbus,
    }:
    rustPlatform.buildRustPackage {
      pname = "airpods-helper";
      version = "0.3.0-unstable-2026-10-07";
      src = fetchFromGitHub {
        owner = "superninjv";
        repo = "airpods-helper";
        rev = "ace961aefc577c3512db5cff786e4ba25fbc4a6a";
        hash = "sha256-PbJpAJasb4kLO98yhLn/VeNKF4vt0Q4qE89gVQlif40=";
      };
      cargoHash = "sha256-FikPVXAXRQUUu+JQxKr8k+C0tUXdOhD2iEglKxTYla8=";
      nativeBuildInputs = [ pkg-config ];
      buildInputs = [ dbus ];
      RUST_TEST_THREADS = "1";
      meta = {
        description = "Native AirPods battery, ear detection and noise control daemon";
        homepage = "https://github.com/superninjv/airpods-helper";
        license = lib.licenses.mit;
        platforms = lib.platforms.linux;
        mainProgram = "airpods-cli";
      };
    }
  ) { };
in
{
  xdg.configFile."wireplumber/wireplumber.conf.d/51-airpods-avrcp.conf".text = ''
    monitor.bluez.properties = {
      bluez5.dummy-avrcp-player = true
    }
  '';
  home.packages = [ airpods ];
  xdg.configFile."airpods-helper/config.toml".source =
    (pkgs.formats.toml { }).generate "airpods-config"
      {
        ear_detection = {
          pause_media = true;
          resume_media = true;
        };
        reconnect = {
          auto_reconnect = true;
          max_retries = 3;
        };
        # Keep the normal PipeWire microphone path; the upstream custom microphone
        # transport is experimental and independent of battery/ear detection.
        mic.enabled = false;
      };

  systemd.user.services.airpods-daemon = {
    Unit = {
      Description = "AirPods battery and automatic media pause";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      # Outgoing AAP SOCK_SEQPACKET connections work without capabilities on
      # this machine (verified with its AirPods 3).
      ExecStart = "${airpods}/bin/airpods-daemon";
      Environment = "PATH=${
        lib.makeBinPath [
          pkgs.pipewire
          pkgs.pulseaudio
          pkgs.wireplumber
        ]
      }";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
