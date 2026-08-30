{ inputs, ... }:
{
  imports = [ inputs.headscale.nixosModules.default ];

  services.headscale = {
    enable = false;
    address = "0.0.0.0";
    port = 8080;

    settings = {
      server_url = "https://hs.paranas.ir";

      prefixes = {
        v4 = "100.64.0.0/10";
        v6 = "fd7a:115c:a1e0::/48";
        allocation = "sequential";
      };

      dns = {
        magic_dns = true;
        base_domain = "tn.paranas.ir";
        override_local_dns = false;
        nameservers = {
          global = [
            "1.1.1.1"
            "8.8.8.8"
          ];
        };
      };

      derp = {
        auto_update_enabled = true;
        update_frequency = "24h";
        server = {
          enabled = true;
          region_id = 999;
          stun_listen_addr = "0.0.0.0:3478";
        };
      };

      database = {
        type = "sqlite";
        sqlite = {
          path = "/var/lib/headscale/db.sqlite";
          write_ahead_log = true;
        };
      };

      log = {
        level = "info";
        format = "text";
      };
    };
  };

  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  networking.firewall = {
    allowedTCPPorts = [ 8080 ];
    allowedUDPPorts = [ 3478 ];
  };
}
