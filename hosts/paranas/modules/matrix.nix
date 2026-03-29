{ pkgs, config, ... }:
let
  domain = "khkhkh";
  matrixHost = "ch.${domain}";
  elementHost = "elm.${domain}";
  baseUrl = "https://${matrixHost}";

  clientConfig = {
    "m.homeserver" = {
      base_url = baseUrl;
    };
  };

  serverConfig = {
    "m.server" = "${matrixHost}:443";
  };

  mkWellKnown = data: ''
    default_type application/json;
    add_header Access-Control-Allow-Origin *;
    return 200 '${builtins.toJSON data}';
  '';
in
{
  environment.systemPackages = with pkgs; [
    matrix-synapse
  ];

  services.postgresql = {
    enable = true;

    ensureDatabases = [ "matrix-synapse" ];
    ensureUsers = [
      {
        name = "matrix-synapse";
        ensureDBOwnership = true;
      }
    ];
  };

  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;

    virtualHosts = {

      # Root domain (for well-known delegation)
      "${domain}" = {
        useACMEHost = "khkhkh";
        forceSSL = true;

        locations."= /.well-known/matrix/server".extraConfig = mkWellKnown serverConfig;
        locations."= /.well-known/matrix/client".extraConfig = mkWellKnown clientConfig;
      };

      # Matrix Synapse host
      "${matrixHost}" = {
        useACMEHost = "khkhkh";
        forceSSL = true;

        extraConfig = ''
          client_max_body_size 200M;
        '';

        locations."/".extraConfig = ''
          return 404;
        '';

        locations."/_matrix".proxyPass = "http://[::1]:8008";
        locations."/_synapse/client".proxyPass = "http://[::1]:8008";
      };

      # Element Web
      "${elementHost}" = {
        useACMEHost = "khkhkh";
        forceSSL = true;

        root = pkgs.element-web.override {
          conf = {
            default_server_config = clientConfig;
          };
        };
      };
    };
  };

  services.coturn = {
    enable = true;
    listening-port = 3479;

    realm = "khkhkh";
    use-auth-secret = true;
    static-auth-secret = "super";
    no-cli = true;
    no-tcp-relay = false;
    min-port = 49152;
    max-port = 49999;
    cert = "${config.security.acme.certs."khkhkhk".directory}/fullchain.pem";
    pkey = "${config.security.acme.certs."khkhkhk".directory}/key.pem";
    extraConfig = ''
      no-multicast-peers
      listening-ip=0.0.0.0
      relay-ip=0.0.0.0
      external-ip=000000
      fingerprint
      lt-cred-mech
    '';
  };

  services.matrix-synapse = {
    enable = true;

    settings = with config.services.coturn; {
      server_name = domain;
      public_baseurl = baseUrl;
      registration_shared_secret = ":pray:";
      max_upload_size = "200M";

      database = {
        name = "psycopg2";
        args = {
          user = "matrix-synapse";
          database = "matrix-synapse";
          host = "/run/postgresql";
        };
      };

      listeners = [
        {
          port = 8008;
          bind_addresses = [ "::1" ];
          type = "http";
          tls = false;
          x_forwarded = true;

          resources = [
            {
              names = [
                "client"
                "federation"
              ];
              compress = true;
            }
          ];
        }
      ];

      turn_uris = [
        "turn:${realm}:3479?transport=udp"
        "turn:${realm}:3479?transport=tcp"
      ];
      turn_shared_secret = static-auth-secret;
      turn_user_lifetime = "1h";
    };
  };

  networking.firewall = {
    allowedUDPPorts = [
      3479
      5349
    ];
    allowedTCPPorts = [
      3479
      5349
    ];

    allowedUDPPortRanges = [
      {
        from = 49152;
        to = 49999;
      }
    ];
  };
}
