{ pkgs, ... }:
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

  services.matrix-synapse = {
    enable = true;

    settings = {
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
    };
  };

  environment.systemPackages = with pkgs; [
    matrix-synapse
  ];
}
