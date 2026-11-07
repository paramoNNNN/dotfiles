{ config, ... }:
{
  # Only the uploader and Immich can read this external library.
  users.groups.activity-captures.members = [
    "paranas"
    config.services.immich.user
  ];
  systemd.services.immich-server.serviceConfig.ReadOnlyPaths = [ "/storage/activity-captures" ];
  services.immich.settings.library.scan = {
    enabled = true;
    cronExpression = "*/10 * * * *";
  };

  # On the large Btrfs storage volume, outside public shares and managed uploads.
  # Fail rather than silently filling the root filesystem if /storage is unavailable.
  systemd.services.systemd-tmpfiles-setup.unitConfig.RequiresMountsFor = [ "/storage" ];
  systemd.tmpfiles.rules = [
    "d /storage/activity-captures 2750 paranas activity-captures -"
    "d /storage/activity-captures/taha-pc 2750 paranas activity-captures -"
    "d /storage/activity-captures/taha-mac 2750 paranas activity-captures -"
  ];
}
