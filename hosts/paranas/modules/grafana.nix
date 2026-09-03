{ pkgs, ... }:

let
  observabilityDashboards = pkgs.runCommand "grafana-observability-dashboards" { } ''
    mkdir -p $out
    cp ${./grafana/navidrome.json} $out/navidrome.json
    cp ${./grafana/navidrome-observability.json} $out/navidrome-observability.json
    cp ${./grafana/node-exporter-full.json} $out/node-exporter-full.json
  '';
in
{
  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    enabledCollectors = [ "systemd" ];
  };

  services.prometheus = {
    enable = true;
    port = 9090;
    extraFlags = [
      "--storage.tsdb.retention.time=7d"
    ];

    scrapeConfigs = [
      {
        job_name = "node";
        scrape_interval = "30s";
        static_configs = [
          { targets = [ "localhost:9100" ]; }
        ];
      }

      {
        job_name = "navidrome";
        scrape_interval = "30s";
        metrics_path = "/metrics_navi";
        static_configs = [
          { targets = [ "localhost:4533" ]; }
        ];
      }
    ];
  };

  services.grafana = {
    enable = true;

    provision = {
      enable = true;
      datasources.settings = {
        apiVersion = 1;
        prune = true;
        datasources = [
          {
            name = "Prometheus";
            uid = "prometheus";
            type = "prometheus";
            access = "proxy";
            url = "http://127.0.0.1:9090";
            editable = false;
            isDefault = true;
            jsonData = {
              timeInterval = "30s";
            };
          }
        ];
      };
      dashboards.settings = {
        apiVersion = 1;
        providers = [
          {
            name = "Observability";
            type = "file";
            disableDeletion = false;
            updateIntervalSeconds = 30;
            options.path = observabilityDashboards;
          }
        ];
      };
    };

    settings = {
      database = {
        type = "sqlite3";
        path = "/var/lib/grafana/data/grafana-v13-clean.db";
      };
      server = {
        http_addr = "0.0.0.0";
        http_port = 3000;
      };
      security = {
        admin_user = "admin";
        admin_password = "$__file{/var/lib/grafana-secrets/admin-password}";
        secret_key = "$__file{/var/lib/grafana-secrets/secret-key}";
      };
    };
  };

  systemd.services.grafana.serviceConfig.ReadOnlyPaths = [ "/var/lib/grafana-secrets" ];
  systemd.tmpfiles.rules = [ "d /var/lib/grafana-secrets 0750 root grafana -" ];
}
