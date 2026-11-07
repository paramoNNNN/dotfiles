{ private, ... }:
{
  services.readeck = {
    enable = true;
    environmentFile = "/var/lib/readeck-secrets/environment";
    settings = {
      server = {
        host = "127.0.0.1";
        port = 8043;
        base_url = "https://read.${private.domain}/";
        allowed_hosts = [ "read.${private.domain}" ];
        trusted_proxies = [ "127.0.0.1/32" ];
      };
      worker.num_workers = 1;
      extractor.workers = 1;
    };
  };
  systemd.services.readeck = {
    unitConfig.ConditionPathExists = "/var/lib/readeck-secrets/environment";
    serviceConfig = {
      MemoryHigh = "256M";
      MemoryMax = "512M";
    };
  };
  systemd.tmpfiles.rules = [ "d /var/lib/readeck-secrets 0700 root root -" ];
  services.nginx.virtualHosts."read.${private.domain}" = {
    useACMEHost = "${private.domain}";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8043";
      extraConfig = ''
        client_max_body_size 20M;
        proxy_read_timeout 120s;
      '';
    };
  };
  security.acme.certs."${private.domain}".extraDomainNames = [ "read.${private.domain}" ];
}
