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

    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = 3000;
      };
      security = {
        admin_user = "admin";
        admin_password = "admin";
        secret_key = "badaboo";
      };
    };
  };
}
