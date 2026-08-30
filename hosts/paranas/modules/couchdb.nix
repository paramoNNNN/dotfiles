{
  services.couchdb = {
    enable = true;
    extraConfigFiles = [ "/var/lib/couchdb-secrets/admin.ini" ];
  };

  systemd.services.couchdb.serviceConfig.ReadOnlyPaths = [ "/var/lib/couchdb-secrets/admin.ini" ];
  systemd.tmpfiles.rules = [ "d /var/lib/couchdb-secrets 0750 root couchdb -" ];
}
