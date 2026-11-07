{ private, config, ... }:
{
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    eventsConfig = ''
      worker_connections 8192;
      multi_accept on;
    '';
    appendHttpConfig = ''
      sendfile on;
      tcp_nopush on;
    '';

    virtualHosts."_default_" = {
      default = true;
      rejectSSL = true;

      locations."/" = {
        return = "404";
      };
    };

    virtualHosts."arkane.${private.legacyDomain}" = {
      useACMEHost = "${private.legacyDomain}";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.vaultwarden.config.ROCKET_PORT}";
      };
    };
    virtualHosts."arkane.${private.domain}" = {
      useACMEHost = "${private.domain}";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.vaultwarden.config.ROCKET_PORT}";
      };
    };

    virtualHosts."nc.${private.legacyDomain}" = {
      useACMEHost = "${private.legacyDomain}";
      forceSSL = true;
    };
    virtualHosts."nc.${private.domain}" = {
      useACMEHost = "${private.domain}";
      forceSSL = true;
    };

    virtualHosts."obs.${private.legacyDomain}" = {
      useACMEHost = "${private.legacyDomain}";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://localhost:5984";
      };
    };
    virtualHosts."obs.${private.domain}" = {
      useACMEHost = "${private.domain}";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://localhost:5984";
      };
    };

    virtualHosts."photos.${private.legacyDomain}" = {
      useACMEHost = "${private.legacyDomain}";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://localhost:2283";
        proxyWebsockets = true;
        recommendedProxySettings = true;
        extraConfig = ''
          client_max_body_size 50000M;
          proxy_read_timeout   600s;
          proxy_send_timeout   600s;
          send_timeout         600s;
        '';
      };
    };
    virtualHosts."photos.${private.domain}" = {
      useACMEHost = "${private.domain}";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://localhost:2283";
        proxyWebsockets = true;
        recommendedProxySettings = true;
        extraConfig = ''
          client_max_body_size 50000M;
          proxy_read_timeout   600s;
          proxy_send_timeout   600s;
          send_timeout         600s;
        '';
      };
    };

    virtualHosts."hs.${private.domain}" = {
      useACMEHost = "${private.domain}";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://localhost:8080";
        proxyWebsockets = true;
      };
    };

    virtualHosts."tv.${private.domain}" = {
      useACMEHost = "${private.domain}";
      forceSSL = true;
      extraConfig = ''
        client_max_body_size 20M;
        add_header X-Content-Type-Options "nosniff";
        add_header Permissions-Policy "accelerometer=(), ambient-light-sensor=(), battery=(), bluetooth=(), camera=(), clipboard-read=(), display-capture=(), document-domain=(), encrypted-media=(), gamepad=(), geolocation=(), gyroscope=(), hid=(), idle-detection=(), interest-cohort=(), keyboard-map=(), local-fonts=(), magnetometer=(), microphone=(), payment=(), publickey-credentials-get=(), serial=(), sync-xhr=(), usb=(), xr-spatial-tracking=()" always;
        add_header Content-Security-Policy "default-src https: data: blob: ; img-src 'self' https://* ; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' https://www.gstatic.com https://www.youtube.com blob:; worker-src 'self' blob:; connect-src 'self'; object-src 'none'; font-src 'self'";

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Protocol $scheme;
        proxy_set_header X-Forwarded-Host $http_host;
        proxy_buffering off;
      '';
      locations."/" = {
        proxyPass = "http://localhost:8096";
      };
      locations."/socket" = {
        proxyPass = "http://localhost:8096";
        proxyWebsockets = true;
      };
    };
    virtualHosts."navi.${private.domain}" = {
      useACMEHost = "${private.domain}";
      forceSSL = true;
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Protocol $scheme;
        proxy_set_header X-Forwarded-Host $http_host;
        proxy_buffering off;
      '';
      locations."/" = {
        proxyPass = "http://localhost:4533";
      };
    };

    virtualHosts."grafana.${private.domain}" = {
      useACMEHost = "${private.domain}";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:3000";
        proxyWebsockets = true;
      };
    };

    virtualHosts."dawarich.${private.domain}" = {
      useACMEHost = "${private.domain}";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8030";
        proxyWebsockets = true;
        extraConfig = ''
          client_max_body_size 250M;
          proxy_read_timeout 300s;
          proxy_send_timeout 300s;
        '';
      };
    };

    virtualHosts."ch.${private.domain}" = {
      useACMEHost = "${private.domain}";
      forceSSL = true;
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Protocol $scheme;
        proxy_set_header X-Forwarded-Host $http_host;
        proxy_buffering off;
      '';
      locations."/ray" = {
        proxyPass = "http://127.0.0.1:1443";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_read_timeout 1d;
          proxy_send_timeout 1d;
          proxy_buffering off;
          proxy_request_buffering off;
          tcp_nodelay on;
        '';
      };
      locations."/assets" = {
        proxyPass = "http://127.0.0.1:1444";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_read_timeout 1d;
          proxy_send_timeout 1d;
          proxy_buffering off;
          proxy_request_buffering off;
          tcp_nodelay on;
        '';
      };
    };
  };
  security.acme = {
    acceptTerms = true;
    defaults.email = "paramoNNN@proton.me";
    certs = {
      "${private.legacyDomain}" = {
        extraDomainNames = [
          "tv.${private.legacyDomain}"
          "obs.${private.legacyDomain}"
          "nc.${private.legacyDomain}"
          "arkane.${private.legacyDomain}"
          "photos.${private.legacyDomain}"
        ];
        group = "nginx";
        dnsProvider = "cloudflare";
        dnsResolver = "1.1.1.1:53";
        environmentFile = "/var/lib/acme-secrets/cloudflare.env";
      };
      "${private.domain}" = {
        extraDomainNames = [
          "tv.${private.domain}"
          "navi.${private.domain}"
          "obs.${private.domain}"
          "nc.${private.domain}"
          "hs.${private.domain}"
          "tn.${private.domain}"
          "ch.${private.domain}"
          "elm.${private.domain}"
          "arkane.${private.domain}"
          "photos.${private.domain}"
          "grafana.${private.domain}"
          "dawarich.${private.domain}"
        ];
        group = "nginx";
        dnsProvider = "arvancloud";
        dnsResolver = "1.1.1.1:53";
        environmentFile = "/var/lib/acme-secrets/arvancloud.env";
      };
    };
  };
  users.users.nginx.extraGroups = [
    "acme"
    "turnserver"
  ];
  systemd.tmpfiles.rules = [ "d /var/lib/acme-secrets 0750 root acme -" ];
}
