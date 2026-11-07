{ private, ... }:
{
  services.homepage-dashboard = {
    enable = true;
    listenPort = 8082;
    allowedHosts = "home.${private.domain}";
    settings = {
      title = "Paranas";
      description = "Music, photos, notes, and server health";
      theme = "dark";
      color = "slate";
      headerStyle = "clean";
      hideVersion = true;
      layout = {
        Media = {
          style = "row";
          columns = 4;
        };
        Personal = {
          style = "row";
          columns = 4;
        };
        Server = {
          style = "row";
          columns = 3;
        };
      };
    };
    services = [
      {
        Media = [
          {
            Navidrome = {
              href = "https://navi.${private.domain}";
              icon = "navidrome.svg";
              description = "Music library";
            };
          }
          {
            Jellyfin = {
              href = "https://tv.${private.domain}";
              icon = "jellyfin.svg";
              description = "Movies and TV";
            };
          }
          {
            Soulseek = {
              href = "https://slskd.${private.domain}";
              icon = "slskd.svg";
              description = "Search and download music";
            };
          }
          {
            Yubal = {
              href = "https://yubal.${private.domain}";
              description = "YouTube Music playlist sync";
            };
          }
        ];
      }
      {
        Personal = [
          {
            Clipboard = {
              href = "https://clipboard.${private.domain}";
              description = "Shared text and files (Tailscale)";
            };
          }
          {
            Immich = {
              href = "https://photos.${private.domain}";
              icon = "immich.svg";
              description = "Photos";
            };
          }
          {
            Nextcloud = {
              href = "https://nc.${private.domain}";
              icon = "nextcloud.svg";
              description = "Files, calendar, and contacts";
            };
          }
          {
            Vaultwarden = {
              href = "https://arkane.${private.domain}";
              icon = "vaultwarden.svg";
              description = "Passwords";
            };
          }
          {
            Readeck = {
              href = "https://read.${private.domain}";
              icon = "readeck.svg";
              description = "Save articles and read later";
            };
          }
          {
            Dawarich = {
              href = "https://dawarich.${private.domain}";
              description = "Location history";
            };
          }
        ];
      }
      {
        Server = [
          {
            Forgejo = {
              href = "https://git.${private.domain}";
              icon = "forgejo.svg";
              description = "Git repositories";
            };
          }
          {
            "PS5 Upload (Tailscale)" = {
              href = "https://ps5.${private.domain}";
              description = "Install and convert PS5 games (Tailscale)";
            };
          }
          {
            "PS5 Upload (LAN)" = {
              href = "http://192.168.1.215:19113";
              description = "Install and convert PS5 games (home network)";
            };
          }
          {
            Grafana = {
              href = "https://grafana.${private.domain}";
              icon = "grafana.svg";
              description = "Metrics and traffic";
            };
          }
          {
            Gotify = {
              href = "https://notify.${private.domain}";
              icon = "gotify.svg";
              description = "Notification inbox";
            };
          }
          {
            Headscale = {
              href = "https://hs.${private.domain}";
              icon = "headscale.svg";
              description = "Private network";
            };
          }
        ];
      }
    ];
    widgets = [
      {
        resources = {
          cpu = true;
          memory = true;
          disk = [
            "/"
            "/storage"
          ];
        };
      }
      {
        datetime = {
          text_size = "lg";
          format = {
            dateStyle = "long";
            timeStyle = "short";
            hour12 = false;
          };
        };
      }
    ];
  };
  systemd.services.homepage-dashboard = {
    environment = {
      HOSTNAME = "127.0.0.1";
      NODE_OPTIONS = "--max-old-space-size=192";
    };
    serviceConfig = {
      MemoryHigh = "256M";
      MemoryMax = "384M";
    };
  };
  services.nginx.virtualHosts."home.${private.domain}" = {
    useACMEHost = "${private.domain}";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8082";
      proxyWebsockets = true;
    };
  };
  security.acme.certs."${private.domain}".extraDomainNames = [ "home.${private.domain}" ];
}
