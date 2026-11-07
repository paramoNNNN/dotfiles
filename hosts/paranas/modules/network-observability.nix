{
  config,
  lib,
  pkgs,
  ...
}:

let
  logFormat = "$traffic_service $server_name $traffic_network $request_method $status $body_bytes_sent $request_length $request_time";
  services = {
    nginx = {
      tcp = [
        80
        443
      ];
      udp = [ ];
    };
    vaultwarden = {
      tcp = [ config.services.vaultwarden.config.ROCKET_PORT ];
      udp = [ ];
    };
    couchdb = {
      tcp = [ 5984 ];
      udp = [ ];
    };
    immich = {
      tcp = [ config.services.immich.port ];
      udp = [ ];
    };
    headscale = {
      tcp = [ config.services.headscale.port ];
      udp = [ 3478 ];
    };
    jellyfin = {
      tcp = [
        8096
        8920
      ];
      udp = [
        7359
        1900
      ];
    };
    navidrome = {
      tcp = [ 4533 ];
      udp = [ ];
    };
    slskd = {
      tcp = [
        5030
        50300
      ];
      udp = [ ];
    };
    gotify = {
      tcp = [ 8041 ];
      udp = [ ];
    };
    readeck = {
      tcp = [ 8043 ];
      udp = [ ];
    };
    homepage = {
      tcp = [ 8082 ];
      udp = [ ];
    };
    grafana = {
      tcp = [ config.services.grafana.settings.server.http_port ];
      udp = [ ];
    };
    samba = {
      tcp = [
        139
        445
      ];
      udp = [
        137
        138
      ];
    };
    teamspeak = {
      tcp = [
        10011
        30033
      ];
      udp = [ 9987 ];
    };
    ssh = {
      tcp = config.services.openssh.ports;
      udp = [ ];
    };
  };
  networks = [
    "tailscale"
    "lan"
    "external"
  ];
  directions = [
    "receive"
    "transmit"
  ];
  counterName =
    service: network: direction:
    "${service}__${network}__${direction}";
  counters = lib.concatStringsSep "\n" (
    lib.concatLists (
      lib.mapAttrsToList (
        service: _:
        lib.concatMap (
          network: map (direction: "counter ${counterName service network direction} { }") directions
        ) networks
      ) services
    )
  );
  serviceChains = lib.concatStringsSep "\n" (
    lib.concatLists (
      lib.mapAttrsToList (
        service: _:
        map (
          direction:
          let
            peer = if direction == "receive" then "saddr" else "daddr";
            interface = if direction == "receive" then "iifname" else "oifname";
            count = network: "counter name ${counterName service network direction} return";
          in
          ''
            chain ${service}_${direction} {
              ${interface} "tailscale0" ${count "tailscale"}
              ip ${peer} { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 169.254.0.0/16 } ${count "lan"}
              ip6 ${peer} { fc00::/7, fe80::/10 } ${count "lan"}
              ${count "external"}
            }
          ''
        ) directions
      ) services
    )
  );
  portRules =
    direction:
    lib.concatStringsSep "\n" (
      lib.concatLists (
        lib.mapAttrsToList (
          service: protocols:
          lib.concatLists (
            lib.mapAttrsToList (
              protocol: ports:
              lib.optional (ports != [ ])
                "${protocol} ${if direction == "receive" then "dport" else "sport"} { ${
                  lib.concatMapStringsSep ", " toString ports
                } } goto ${service}_${direction}"
            ) protocols
          )
        ) services
      )
    );
  nftRules = pkgs.writeText "service-traffic.nft" ''
    # Own accounting table only; never flush or change the host firewall.
    add table inet service_traffic
    flush table inet service_traffic
    table inet service_traffic {
      ${counters}
      ${serviceChains}
      chain incoming {
        type filter hook input priority 10; policy accept;
        iifname "lo" return
        ${portRules "receive"}
      }
      chain outgoing {
        type filter hook output priority 10; policy accept;
        oifname "lo" return
        ${portRules "transmit"}
      }
    }
  '';
  collector = pkgs.writeText "service-traffic.py" (
    builtins.readFile ./network-observability/collect.py
  );
in
{
  services.nginx.appendHttpConfig = ''
    map $server_name $traffic_service {
      default other;
      ~^arkane\. vaultwarden;
      ~^nc\. nextcloud;
      ~^obs\. couchdb;
      ~^photos\. immich;
      ~^hs\. headscale;
      ~^tv\. jellyfin;
      ~^navi\. navidrome;
      ~^grafana\. grafana;
      ~^slskd\. slskd;
      ~^yubal\. yubal;
      ~^notify\. gotify;
      ~^home\. homepage;
      ~^read\. readeck;
      ~^git\. forgejo;
      ~^dawarich\. dawarich;
      ~^ch\. tunnel;
    }
    geo $traffic_network {
      default external;
      127.0.0.0/8 loopback;
      ::1/128 loopback;
      10.0.0.0/8 lan;
      172.16.0.0/12 lan;
      192.168.0.0/16 lan;
      169.254.0.0/16 lan;
      fc00::/7 lan;
      fe80::/10 lan;
      100.64.0.0/10 overlay_or_cgnat;
      fd7a:115c:a1e0::/48 overlay_or_cgnat;
    }
    log_format service_traffic '${logFormat}';
    access_log /var/log/nginx/access.log combined;
    access_log /var/log/nginx/service-traffic.log service_traffic buffer=64k flush=5s;
  '';

  services.prometheus.exporters.nginxlog = {
    enable = true;
    listenAddress = "127.0.0.1";
    group = config.services.nginx.group;
    settings.namespaces = [
      {
        name = "service_nginx";
        format = logFormat;
        source.files = [ "/var/log/nginx/service-traffic.log" ];
        relabel_configs =
          map
            (label: {
              target_label = label;
              from = "traffic_${label}";
            })
            [
              "service"
              "network"
            ]
          ++ [
            {
              target_label = "vhost";
              from = "server_name";
            }
          ];
      }
    ];
  };
  services.prometheus.scrapeConfigs = [
    {
      job_name = "nginx-traffic";
      scrape_interval = "30s";
      static_configs = [
        {
          targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.nginxlog.port}" ];
          labels.node_instance = "localhost:${toString config.services.prometheus.exporters.node.port}";
        }
      ];
    }
  ];
  services.prometheus.rules = [
    (builtins.toJSON {
      groups = [
        {
          name = "service-traffic-health";
          rules = [
            {
              alert = "ServiceTrafficCollectionStale";
              expr = "time() - service_network_collector_timestamp_seconds > 90 or absent(service_network_collector_timestamp_seconds)";
              for = "5m";
              labels.severity = "warning";
              annotations = {
                summary = "Service traffic collection has stopped";
                description = "The live network counters have not been collected recently. Check service-traffic-accounting and service-traffic-collector.";
              };
            }
            {
              alert = "NginxTrafficExporterDown";
              expr = ''up{job="nginx-traffic"} == 0'';
              for = "5m";
              labels.severity = "warning";
              annotations = {
                summary = "Nginx traffic exporter is unreachable";
                description = "Per-route network metrics are unavailable. Check prometheus-nginxlog-exporter.";
              };
            }
          ];
        }
      ];
    })
  ];
  services.prometheus.exporters.node = {
    enabledCollectors = [ "textfile" ];
    extraFlags = [ "--collector.textfile.directory=/var/lib/prometheus-node-textfiles" ];
  };

  systemd.services.service-traffic-accounting = {
    description = "Service network byte counters";
    wantedBy = [ "multi-user.target" ];
    after = [
      "network-pre.target"
      "firewall.service"
    ];
    restartTriggers = [ nftRules ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.nftables}/bin/nft -f ${nftRules}";
      ExecStop = "${pkgs.nftables}/bin/nft delete table inet service_traffic";
      CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
    };
  };
  systemd.services.service-traffic-collector = {
    description = "Export service network counters to node exporter";
    requires = [ "service-traffic-accounting.service" ];
    after = [ "service-traffic-accounting.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.python3}/bin/python3 ${collector} ${pkgs.nftables}/bin/nft /var/lib/prometheus-node-textfiles/service-traffic.prom";
      CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ "/var/lib/prometheus-node-textfiles" ];
    };
  };
  systemd.timers.service-traffic-collector = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "15s";
      OnUnitActiveSec = "15s";
      AccuracySec = "1s";
    };
  };
  systemd.tmpfiles.rules = [
    "d /var/lib/prometheus-node-textfiles 0755 root root -"
    "f /var/log/nginx/service-traffic.log 0640 ${config.services.nginx.user} ${config.services.nginx.group} -"
  ];
}
