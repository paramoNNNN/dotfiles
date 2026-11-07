{ private, lib, ... }:

{
  services.slskd = {
    enable = true;
    user = "paranas";
    group = "users";
    environmentFile = "/var/lib/slskd-secrets/environment";
    openFirewall = true;
    settings = {
      web.ip_address = "127.0.0.1";
      directories = {
        downloads = "/storage/media/Music";
        incomplete = "/storage/slskd-incomplete";
      };
      shares = {
        directories = [ "/storage/media/Music" ];
        cache = {
          storage_mode = "disk";
          workers = 1;
        };
      };
      transfers = {
        download.slots = 4;
        upload = {
          slots = 2;
          speed_limit = 1024;
        };
      };
    };
  };
  systemd.services.slskd = {
    unitConfig.RequiresMountsFor = [ "/storage" ];
    unitConfig.ConditionPathExists = "/var/lib/slskd-secrets/environment";
    serviceConfig = {
      UMask = "0002";
      MemoryHigh = "384M";
      MemoryMax = "512M";
      ReadOnlyPaths = lib.mkForce [ ];
      ReadWritePaths = [ "/storage/media/Music" ];
    };
  };

  virtualisation.oci-containers.containers.yubal = {
    image = "ghcr.io/guillevc/yubal:0.10.0";
    user = "1000:100";
    environment = {
      PUID = "1000";
      PGID = "100";
      YUBAL_HOST = "0.0.0.0";
      YUBAL_PORT = "8000";
      YUBAL_AUDIO_FORMAT = "opus";
      YUBAL_DOWNLOAD_UGC = "true";
      YUBAL_SCHEDULER_ENABLED = "true";
      YUBAL_SCHEDULER_CRON = "30 3 * * *";
      YUBAL_TZ = "Asia/Tehran";
      YUBAL_CORS_ORIGINS = ''["https://yubal.${private.domain}"]'';
    };
    ports = [ "127.0.0.1:8040:8000" ];
    volumes = [
      "/storage/media/Music:/app/data"
      "/var/lib/yubal:/app/config"
    ];
    extraOptions = [
      "--memory=512m"
      "--cpus=0.75"
      "--cap-drop=ALL"
      "--security-opt=no-new-privileges"
    ];
  };
  systemd.services.docker-yubal.unitConfig.RequiresMountsFor = [ "/storage" ];

  systemd.tmpfiles.rules = [
    "d /var/lib/slskd-secrets 0700 root root -"
    "d /storage/slskd-incomplete 2770 paranas users -"
    "d /var/lib/yubal 0750 paranas users -"
  ];

  services.nginx.virtualHosts = {
    "slskd.${private.domain}" = {
      useACMEHost = "${private.domain}";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:5030";
        proxyWebsockets = true;
      };
    };
    "yubal.${private.domain}" = {
      useACMEHost = "${private.domain}";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8040";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_read_timeout 600s;
          client_max_body_size 10M;
        '';
      };
    };
  };
  security.acme.certs."${private.domain}".extraDomainNames = [
    "slskd.${private.domain}"
    "yubal.${private.domain}"
  ];
}
