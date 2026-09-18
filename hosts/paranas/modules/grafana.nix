{ lib, pkgs, ... }:

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

    alertmanagers = [
      {
        static_configs = [
          { targets = [ "127.0.0.1:9093" ]; }
        ];
      }
    ];

    rules = [
      (builtins.toJSON {
        groups = [
          {
            name = "host-health";
            rules = [
              {
                alert = "ExporterDown";
                expr = ''up{job=~"node|navidrome"} == 0'';
                for = "5m";
                labels.severity = "critical";
                annotations = {
                  summary = "{{ $labels.job }} is unreachable";
                  description = "Prometheus has been unable to scrape {{ $labels.instance }} for 5 minutes.";
                };
              }
              {
                alert = "HighCPUUsage";
                expr = ''100 * (1 - avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m]))) > 90'';
                for = "10m";
                labels.severity = "warning";
                annotations = {
                  summary = "High CPU usage on {{ $labels.instance }}";
                  description = "CPU usage has exceeded 90% for 10 minutes.";
                };
              }
              {
                alert = "LowAvailableMemory";
                expr = "100 * node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes < 10";
                for = "10m";
                labels.severity = "warning";
                annotations = {
                  summary = "Low available memory on {{ $labels.instance }}";
                  description = "Available memory has remained below 10% for 10 minutes.";
                };
              }
              {
                alert = "HighCPUPressure";
                expr = "100 * rate(node_pressure_cpu_waiting_seconds_total[5m]) > 20";
                for = "10m";
                labels.severity = "warning";
                annotations = {
                  summary = "High CPU pressure on {{ $labels.instance }}";
                  description = "Tasks have spent over 20% of time waiting for CPU for 10 minutes.";
                };
              }
              {
                alert = "HighMemoryPressure";
                expr = "100 * rate(node_pressure_memory_waiting_seconds_total[5m]) > 10";
                for = "10m";
                labels.severity = "warning";
                annotations = {
                  summary = "High memory pressure on {{ $labels.instance }}";
                  description = "Tasks have spent over 10% of time stalled by memory pressure for 10 minutes.";
                };
              }
              {
                alert = "RootFilesystemLowSpace";
                expr = ''100 * node_filesystem_avail_bytes{mountpoint="/",fstype!~"tmpfs|overlay"} / node_filesystem_size_bytes{mountpoint="/",fstype!~"tmpfs|overlay"} < 10'';
                for = "15m";
                labels.severity = "warning";
                annotations = {
                  summary = "Root filesystem is nearly full on {{ $labels.instance }}";
                  description = "Less than 10% disk space has been available for 15 minutes.";
                };
              }
              {
                alert = "HighNetworkReceiveBandwidth";
                expr = ''sum by (instance) (rate(node_network_receive_bytes_total{device!~"lo|veth.*|docker.*|br-.*"}[5m])) > 2000000'';
                for = "10m";
                labels.severity = "warning";
                annotations = {
                  summary = "High inbound network traffic on {{ $labels.instance }}";
                  description = "Inbound traffic has exceeded 2 MB/s for 10 minutes.";
                };
              }
              {
                alert = "HighNetworkTransmitBandwidth";
                expr = ''sum by (instance) (rate(node_network_transmit_bytes_total{device!~"lo|veth.*|docker.*|br-.*"}[5m])) > 2000000'';
                for = "10m";
                labels.severity = "warning";
                annotations = {
                  summary = "High outbound network traffic on {{ $labels.instance }}";
                  description = "Outbound traffic has exceeded 2 MB/s for 10 minutes.";
                };
              }
            ];
          }
        ];
      })
    ];
  };

  services.prometheus.alertmanager = {
    enable = true;
    listenAddress = "127.0.0.1";
    environmentFile = "/var/lib/prometheus-alertmanager-secrets/telegram.env";
    configuration = {
      global.resolve_timeout = "5m";
      route = {
        receiver = "telegram";
        group_by = [
          "alertname"
          "instance"
        ];
        group_wait = "30s";
        group_interval = "5m";
        repeat_interval = "4h";
      };
      receivers = [
        {
          name = "telegram";
          telegram_configs = [
            {
              bot_token = "$TELEGRAM_BOT_TOKEN";
              chat_id = 516036245;
              send_resolved = true;
              parse_mode = "HTML";
              message = ''
                {{ if eq .Status "firing" }}🔥 <b>FIRING</b>{{ else }}✅ <b>RESOLVED</b>{{ end }}
                {{ range .Alerts }}
                <b>{{ .Annotations.summary }}</b>
                {{ .Annotations.description }}
                {{ end }}
              '';
            }
          ];
        }
      ];
    };
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
      # Grafana 13.1.3 serializes timestamps from these background jobs in a
      # format that its SQLite KV store cannot parse after a restart.  Keep the
      # optional network checks disabled so a reboot cannot poison startup.
      analytics = {
        reporting_enabled = false;
        check_for_updates = false;
        check_for_plugin_updates = false;
      };
      plugins = {
        preinstall_disabled = true;
        public_key_retrieval_disabled = true;
      };
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

  systemd.services.grafana = {
    preStart = lib.mkBefore ''
      if [ -f /var/lib/grafana/data/grafana-v13-clean.db ]; then
        ${pkgs.sqlite}/bin/sqlite3 /var/lib/grafana/data/grafana-v13-clean.db \
          "DELETE FROM kv_store WHERE value LIKE '% m=+%';"
      fi
    '';
    serviceConfig.ReadOnlyPaths = [ "/var/lib/grafana-secrets" ];
  };
  systemd.tmpfiles.rules = [
    "d /var/lib/grafana-secrets 0750 root grafana -"
    "d /var/lib/prometheus-alertmanager-secrets 0700 root root -"
  ];
}
