{
  private,
  inputs,
  pkgs,
  config,
  lib,
  ...
}:
let
  # MagicDNS extra records are exact names, not wildcard DNS rules.
  # Derive service names so new nginx services also work away from the LAN.
  serviceNames = lib.filter (
    name:
    name != "hs.${private.domain}"
    && lib.any (domain: name == domain || lib.hasSuffix ".${domain}" name) [
      private.domain
      private.legacyDomain
    ]
  ) (builtins.attrNames config.services.nginx.virtualHosts);
in
{
  imports = [ inputs.headscale.nixosModules.default ];

  services.headscale = {
    # Headscale 0.29 does not expose Tailscale's UseWithExitNode DNS flag.
    # Opt only this router into it; keep the rest of the resolver policy intact.
    package = pkgs.headscale.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        substituteInPlace hscontrol/types/config.go \
          --replace-fail 'Addr: nsStr,' 'Addr: nsStr, UseWithExitNode: nsStr == "100.64.0.8",'
        cat > hscontrol/types/openwrt_dns_test.go <<'EOF'
        package types
        import "testing"
        func TestOpenWrtExitNodeDNS(t *testing.T) {
          var d DNSConfig
          d.Nameservers.Global = []string{"100.64.0.8", "1.1.1.1"}
          resolvers := d.globalResolvers()
          if len(resolvers) != 2 || resolvers[0].Addr != "100.64.0.8" || !resolvers[0].UseWithExitNode || resolvers[1].UseWithExitNode {
            t.Fatalf("unexpected exit-node DNS resolver policy: %+v", resolvers)
          }
        }
        EOF
      '';
      checkPhase = ''
        runHook preCheck
        go test -trimpath=false -mod=vendor -short ./hscontrol/types -run '^TestOpenWrtExitNodeDNS$'
        runHook postCheck
      '';
    });
    enable = true;
    address = "0.0.0.0";
    port = 8080;

    settings = {
      server_url = "https://hs.${private.domain}";

      policy = {
        mode = "file";
        path = builtins.toFile "headscale-policy.json" (
          builtins.toJSON {
            groups."group:admins" = [
              "taha@"
              "saeed@"
            ];

            grants = [
              {
                src = [ "autogroup:member" ];
                dst = [ "100.64.0.8" ];
                ip = [
                  "udp:53"
                  "tcp:53"
                ];
              }
              {
                src = [ "group:admins" ];
                dst = [ "*" ];
                ip = [ "*" ];
              }
              {
                src = [ "autogroup:member" ];
                dst = [
                  "autogroup:self"
                  "autogroup:tagged"
                  # Allow exit-node traffic, including through OpenWrt.
                  "autogroup:internet"
                ];
                ip = [ "*" ];
              }
            ];

            nodeAttrs = [
              {
                target = [ "100.64.0.3/32" ];
                attr = [ "disable-linux-cgnat-drop-rule" ];
              }
            ];
          }
        );
      };

      prefixes = {
        v4 = "100.64.0.0/10";
        v6 = "fd7a:115c:a1e0::/48";
        allocation = "sequential";
      };

      dns = {
        magic_dns = true;
        base_domain = "tn.${private.domain}";
        override_local_dns = true;
        extra_records =
          map
            (name: {
              inherit name;
              type = "A";
              value = "100.64.0.3";
            })
            (
              lib.unique (
                [
                  private.domain
                  private.legacyDomain
                ]
                ++ serviceNames
              )
            );
        nameservers = {
          global = [
            "100.64.0.8"
          ];
        };
      };

      derp = {
        auto_update_enabled = true;
        update_frequency = "24h";
        server = {
          enabled = true;
          region_id = 999;
          region_code = "paranas";
          region_name = "Paranas DERP";
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
