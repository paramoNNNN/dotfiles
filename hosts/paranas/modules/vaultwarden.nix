{
  services.vaultwarden = {
    enable = true;
    backupDir = "/storage/backups/vaultwarden/backup";
    environmentFile = "/home/paranas/vw";
    config = {
      DOMAIN = "rick";
      SIGNUPS_ALLOWED = false;

      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
      ROCKET_LOG = "critical";
    };
  };
}
