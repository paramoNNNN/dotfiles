{ pkgs, ... }:

let
  network = "endurain";
  secretFile = "/var/lib/endurain-secrets/environment";
in
{
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      endurain-postgres = {
        image = "postgres:18";
        environment = {
          POSTGRES_DB = "endurain";
          POSTGRES_USER = "endurain";
          PGDATA = "/var/lib/postgresql/data/pgdata";
        };
        environmentFiles = [ secretFile ];
        volumes = [ "endurain-postgres:/var/lib/postgresql/data" ];
        extraOptions = [
          "--memory=512m"
          "--network=${network}"
        ];
      };

      endurain-redis = {
        image = "redis:8-alpine";
        cmd = [
          "redis-server"
          "--appendonly"
          "yes"
        ];
        volumes = [ "endurain-redis:/data" ];
        extraOptions = [
          "--memory=128m"
          "--network=${network}"
        ];
      };

      endurain = {
        image = "codeberg.org/endurain-project/endurain:latest";
        dependsOn = [
          "endurain-postgres"
          "endurain-redis"
        ];
        environment = {
          TZ = "Asia/Tehran";
          ENDURAIN_HOST = "https://endurain.dummy";
          BEHIND_PROXY = "true";
          TRUSTED_PROXIES = "172.19.0.0/16";
          DB_HOST = "endurain-postgres";
          DB_PORT = "5432";
          DB_USER = "endurain";
          DB_DATABASE = "endurain";
          RATE_LIMIT_STORAGE_URI = "redis://endurain-redis:6379/0";
          AUTH_SECURITY_STORAGE_URI = "redis://endurain-redis:6379/0";
          ENVIRONMENT = "production";
        };
        environmentFiles = [ secretFile ];
        ports = [ "127.0.0.1:8020:8080" ];
        volumes = [
          "endurain-data:/app/backend/data"
          "endurain-logs:/app/backend/logs"
        ];
        extraOptions = [
          "--memory=1g"
          "--network=${network}"
        ];
      };
    };
  };

  systemd.services = {
    endurain-network = {
      description = "Endurain Docker network";
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
            --subnet 172.19.0.0/16 ${network}
      '';
    };

    docker-endurain-postgres = {
      after = [ "endurain-network.service" ];
      requires = [ "endurain-network.service" ];
    };
    docker-endurain-redis = {
      after = [ "endurain-network.service" ];
      requires = [ "endurain-network.service" ];
    };
    docker-endurain = {
      after = [ "endurain-network.service" ];
      requires = [ "endurain-network.service" ];
    };
  };

  systemd.tmpfiles.rules = [ "d /var/lib/endurain-secrets 0700 root root -" ];
}
