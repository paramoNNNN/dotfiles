{
  private,
  lib,
  pkgs,
  ...
}:
let
  notify = pkgs.writeShellApplication {
    name = "paranas-notify";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.curl
      pkgs.jq
    ];
    text = ''
      : "''${GOTIFY_TOKEN:?Gotify application token is not configured}"
      unit="''${1:-manual-test}"
      umask 077
      payload=$(mktemp)
      headers=$(mktemp)
      trap 'rm -f "$payload" "$headers"' EXIT
      jq -n --arg unit "$unit" '{
        title: "Paranas service failed",
        message: ($unit + " failed on Paranas. Check: journalctl -u " + $unit),
        priority: 8
      }' > "$payload"
      # Read the header from a protected file so the token is not in argv.
      printf 'X-Gotify-Key: %s\n' "$GOTIFY_TOKEN" > "$headers"
      curl --fail --silent --show-error --output /dev/null \
        --connect-timeout 3 --max-time 10 --retry 2 --retry-delay 2 \
        --header @"$headers" --header 'Content-Type: application/json' \
        --data-binary @"$payload" http://127.0.0.1:8041/message
    '';
  };
  watchedServices = [
    "work-daily-brief"
    "work-calendar-meetings"
    "work-archive-notes"
    "immich-server"
    "immich-machine-learning"
    "navidrome"
    "jellyfin"
    "nginx"
    "postgresql"
    "phpfpm-nextcloud"
    "nextcloud-cron"
    "couchdb"
    "obsidian-livesync-bridge"
    "vaultwarden"
    "slskd"
    "homepage-dashboard"
    "readeck"
    "docker-yubal"
    "docker-dawarich"
    "docker-dawarich-sidekiq"
    "docker-dawarich-db"
    "docker-dawarich-redis"
    "prometheus"
    "prometheus-node-exporter"
    "prometheus-nginxlog-exporter"
    "service-traffic-collector"
  ];
in
{
  services.gotify = {
    enable = true;
    environment = {
      GOTIFY_SERVER_LISTENADDR = "127.0.0.1";
      GOTIFY_SERVER_PORT = 8041;
      GOTIFY_REGISTRATION = "false";
    };
    environmentFiles = [ "/var/lib/gotify-secrets/server.env" ];
  };
  services.prometheus.alertmanagerGotify = {
    enable = true;
    bindAddress = "127.0.0.1";
    port = 8042;
    environmentFile = "/var/lib/gotify-secrets/notifications.env";
    messageAnnotation = "description";
    extendedDetails = true;
    metrics.username = "";
    gotifyEndpoint = {
      host = "127.0.0.1";
      port = 8041;
      tls = false;
    };
  };
  systemd.services =
    lib.genAttrs watchedServices (_: {
      onFailure = [ "gotify-failure@%n.service" ];
    })
    // {
      gotify-server = {
        unitConfig.ConditionPathExists = "/var/lib/gotify-secrets/server.env";
        serviceConfig = {
          MemoryHigh = "96M";
          MemoryMax = "128M";
        };
      };
      alertmanager-gotify-bridge = {
        after = [ "gotify-server.service" ];
        wants = [ "gotify-server.service" ];
        unitConfig.ConditionPathExists = "/var/lib/gotify-secrets/notifications.env";
        serviceConfig = {
          MemoryHigh = "48M";
          MemoryMax = "64M";
          Restart = "on-failure";
          RestartSec = "10s";
        };
      };
      "gotify-failure@" = {
        description = "Send a failed service notification to Gotify";
        after = [ "gotify-server.service" ];
        wants = [ "gotify-server.service" ];
        unitConfig.ConditionPathExists = "/var/lib/gotify-secrets/notifications.env";
        serviceConfig = {
          Type = "oneshot";
          DynamicUser = true;
          EnvironmentFile = "/var/lib/gotify-secrets/notifications.env";
          ExecStart = "${notify}/bin/paranas-notify %i";
          TimeoutStartSec = "45s";
          MemoryMax = "64M";
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectHome = true;
          ProtectSystem = "strict";
        };
      };
    };
  services.nginx.virtualHosts."notify.${private.domain}" = {
    useACMEHost = "${private.domain}";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8041";
      proxyWebsockets = true;
    };
  };
  security.acme.certs."${private.domain}".extraDomainNames = [ "notify.${private.domain}" ];
  systemd.tmpfiles.rules = [ "d /var/lib/gotify-secrets 0700 root root -" ];
}
