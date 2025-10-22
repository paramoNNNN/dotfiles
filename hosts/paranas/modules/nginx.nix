{ config, ... }:
{
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts."rick" = {
      useACMEHost = "rick";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.vaultwarden.config.ROCKET_PORT}";
      };
    };
    virtualHosts."nextcloud" = {
      useACMEHost = "nextcloud";
      forceSSL = true;
    };
    virtualHosts."obsidian" = {
      useACMEHost = "obsidian";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://localhost:5984";
      };
    };

  };
  security.acme = {
    acceptTerms = true;
    defaults.email = "rick";
    certs = {
      "rick" = {
        extraDomainNames = [
          "roll"
        ];
        group = "nginx";
        dnsProvider = "cloudflare";
        dnsResolver = "1.1.1.1:53";
        # TODO: setup with agent
        environmentFile = "/home/paranas/cf";
      };
    };
  };
  users.users.nginx.extraGroups = [ "acme" ];
}
