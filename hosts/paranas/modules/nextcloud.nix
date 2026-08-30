{ pkgs, config, ... }:
{
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud34;
    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps)
        contacts
        calendar
        notes
        ;
    };

    hostName = "roll";
    https = true;

    config.adminpassFile = "/var/lib/nextcloud-secrets/admin-password";
    config.dbtype = "sqlite";
  };

  systemd.tmpfiles.rules = [ "d /var/lib/nextcloud-secrets 0750 root nextcloud -" ];
}
