{ private, config, ... }:
{
  environment.systemPackages = [ config.services.forgejo.package ];
  services.forgejo = {
    enable = true;
    database.type = "sqlite3";
    settings = {
      server = {
        DOMAIN = "git.${private.domain}";
        ROOT_URL = "https://git.${private.domain}/";
        HTTP_ADDR = "127.0.0.1";
        HTTP_PORT = 8046;
        DISABLE_SSH = false;
        START_SSH_SERVER = false;
        SSH_DOMAIN = "git.${private.domain}";
        SSH_PORT = 22;
        SSH_USER = "forgejo";
      };
      service.DISABLE_REGISTRATION = true;
      service.REQUIRE_SIGNIN_VIEW = true;
      session.COOKIE_SECURE = true;
    };
  };

  systemd.services.forgejo.serviceConfig = {
    MemoryHigh = "256M";
    MemoryMax = "512M";
  };

  services.nginx.virtualHosts."git.${private.domain}" = {
    useACMEHost = "${private.domain}";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8046";
      extraConfig = ''
        client_max_body_size 512M;
        proxy_read_timeout 300s;
      '';
    };
  };
  security.acme.certs."${private.domain}".extraDomainNames = [ "git.${private.domain}" ];
}
