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
  };
  security.acme = {
    acceptTerms = true;
    defaults.email = "rick";
    certs = {
      "rick" = {
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
