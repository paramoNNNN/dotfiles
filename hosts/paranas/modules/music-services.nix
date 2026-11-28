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

  systemd.tmpfiles.rules = [
    "d /var/lib/slskd-secrets 0700 root root -"
    "d /storage/slskd-incomplete 2770 paranas users -"
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
  };
  security.acme.certs."${private.domain}".extraDomainNames = [
    "slskd.${private.domain}"
  ];
}
