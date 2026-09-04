{ pkgs, ... }:

let
  network = "dawarich";
  secretFile = "/var/lib/dawarich-secrets/environment";
  commonEnvironment = {
    RAILS_ENV = "production";
    REDIS_URL = "redis://dawarich-redis:6379";
    DATABASE_HOST = "dawarich-db";
    DATABASE_PORT = "5432";
    DATABASE_USERNAME = "postgres";
    DATABASE_NAME = "dawarich_development";
    APPLICATION_HOSTS = "dawarich.dummy,localhost,127.0.0.1";
    APPLICATION_PROTOCOL = "https";
    TIME_ZONE = "Asia/Tehran";
    PROMETHEUS_EXPORTER_ENABLED = "false";
    RAILS_LOG_TO_STDOUT = "true";
    SELF_HOSTED = "true";
    STORE_GEODATA = "true";
  };
in
{
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      dawarich-redis = {
        image = "redis:7.4-alpine";
        cmd = [
          "redis-server"
          "--save"
          "900"
          "1"
          "--save"
          "300"
          "10"
          "--appendonly"
          "no"
        ];
        volumes = [ "dawarich-shared:/data" ];
        extraOptions = [
          "--memory=128m"
          "--network=${network}"
        ];
      };

      dawarich-db = {
        image = "postgis/postgis:17-3.5-alpine";
        environment = {
          POSTGRES_USER = "postgres";
          POSTGRES_DB = "dawarich_development";
        };
        environmentFiles = [ secretFile ];
        volumes = [
          "dawarich-db:/var/lib/postgresql/data"
          "dawarich-shared:/var/shared"
        ];
        extraOptions = [
          "--memory=512m"
          "--shm-size=1g"
          "--network=${network}"
        ];
      };

      dawarich = {
        image = "freikin/dawarich:latest";
        entrypoint = "web-entrypoint.sh";
        cmd = [
          "bin/rails"
          "server"
          "-p"
          "3000"
          "-b"
          "::"
        ];
        dependsOn = [
          "dawarich-db"
          "dawarich-redis"
        ];
        environment = commonEnvironment // {
          WEB_CONCURRENCY = "1";
        };
        environmentFiles = [ secretFile ];
        ports = [ "127.0.0.1:8030:3000" ];
        volumes = [
          "dawarich-public:/var/app/public"
          "dawarich-watched:/var/app/tmp/imports/watched"
          "dawarich-storage:/var/app/storage"
          "dawarich-db:/dawarich_db_data"
        ];
        extraOptions = [
          "--memory=768m"
          "--cpus=0.75"
          "--network=${network}"
        ];
      };

      dawarich-sidekiq = {
        image = "freikin/dawarich:latest";
        entrypoint = "sidekiq-entrypoint.sh";
        cmd = [ "sidekiq" ];
        dependsOn = [
          "dawarich-db"
          "dawarich-redis"
          "dawarich"
        ];
        environment = commonEnvironment // {
          BACKGROUND_PROCESSING_CONCURRENCY = "1";
        };
        environmentFiles = [ secretFile ];
        volumes = [
          "dawarich-public:/var/app/public"
          "dawarich-watched:/var/app/tmp/imports/watched"
          "dawarich-storage:/var/app/storage"
        ];
        extraOptions = [
          "--memory=768m"
          "--cpus=0.75"
          "--network=${network}"
        ];
      };
    };
  };

  systemd.services = {
    dawarich-network = {
      description = "Dawarich Docker network";
      after = [ "docker.service" ];
      requires = [ "docker.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        ${pkgs.docker}/bin/docker network inspect ${network} >/dev/null 2>&1 \
          || ${pkgs.docker}/bin/docker network create \
            --subnet 172.20.0.0/16 ${network}
      '';
    };

    docker-dawarich-redis = {
      after = [ "dawarich-network.service" ];
      requires = [ "dawarich-network.service" ];
    };
    docker-dawarich-db = {
      after = [ "dawarich-network.service" ];
      requires = [ "dawarich-network.service" ];
    };
    docker-dawarich = {
      after = [ "dawarich-network.service" ];
      requires = [ "dawarich-network.service" ];
    };
    docker-dawarich-sidekiq = {
      after = [ "dawarich-network.service" ];
      requires = [ "dawarich-network.service" ];
    };
  };

  systemd.tmpfiles.rules = [ "d /var/lib/dawarich-secrets 0700 root root -" ];
}
