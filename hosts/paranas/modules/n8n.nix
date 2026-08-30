{ pkgs, ... }:

{
  services.n8n = {
    enable = true;

    environment = {
      DB_SQLITE_POOL_SIZE = "2";
      EXECUTIONS_DATA_MAX_AGE = "168";
      EXECUTIONS_DATA_PRUNE = "true";
      GENERIC_TIMEZONE = "Asia/Tehran";
      N8N_DIAGNOSTICS_ENABLED = "false";
      N8N_EDITOR_BASE_URL = "";
      N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS = "true";
      N8N_HOST = "n8n.paranas.ir";
      N8N_LISTEN_ADDRESS = "0.0.0.0";
      N8N_LOG_LEVEL = "warn";
      N8N_PORT = "5678";
      N8N_PROTOCOL = "https";
      N8N_RESTRICT_FILE_ACCESS_TO = "/var/lib/n8n-files;/var/lib/obsidian-vault";
      N8N_RUNNERS_TASK_TIMEOUT = "300";
      N8N_TEMPLATES_ENABLED = "false";
      N8N_UNVERIFIED_PACKAGES_ENABLED = "false";
      N8N_VERSION_NOTIFICATIONS_ENABLED = "false";
      N8N_BLOCK_ENV_ACCESS_IN_NODE = "false";
      N8N_COMPRESSION_NODE_MAX_DECOMPRESSED_SIZE_BYTES = "268435456";
      N8N_COMPRESSION_NODE_MAX_ZIP_ENTRIES = "1000";
      N8N_WEBHOOK_URL = "https://n8n.paranas.ir/";
      NODE_OPTIONS = "--max-old-space-size=1024";
    };

  };
  systemd.services.n8n = {
    serviceConfig = {
      EnvironmentFile = "/var/lib/n8n-secrets/environment";
      MemoryHigh = "1280M";
      MemoryMax = "1536M";
      StateDirectory = [
        "n8n"
        "n8n-files/captures"
        "n8n-files/digests"
      ];
      StateDirectoryMode = "0750";
      UMask = "0007";
      SupplementaryGroups = [ "obsidian-vault" ];
      ReadWritePaths = [ "/var/lib/obsidian-vault" ];
      TasksMax = 256;
    };
  };

  environment.systemPackages = [ pkgs.apacheHttpd ];
}
