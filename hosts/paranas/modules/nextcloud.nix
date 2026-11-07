{
  private,
  pkgs,
  config,
  ...
}:
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

    hostName = "nc.${private.domain}";
    https = true;

    config.dbtype = "sqlite";
  };

  systemd.tmpfiles.rules = [ "d /var/lib/nextcloud-secrets 0750 root nextcloud -" ];
}
