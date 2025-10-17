{ pkgs, config, ... }:
{
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud31;
    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps)
        contacts
        calendar
        notes
        ;
    };

    hostName = "roll";
    https = true;

    config.adminpassFile = "/home/paranas/nc";
    config.dbtype = "sqlite";
  };
}
