{ config, pkgs, ... }:

{
  services.syncthing = {
    enable = true;
    user = "paranas";
    group = "users";
    dataDir = "/var/lib/syncthing";
    configDir = "/var/lib/syncthing";
    guiAddress = "127.0.0.1:8384";
    openDefaultPorts = true;

    # Keep devices and folder sharing selected in the web interface across rebuilds.
    overrideDevices = false;
    overrideFolders = false;
    settings.options.urAccepted = -1;
  };

  systemd.services.syncthing = {
    unitConfig.RequiresMountsFor = [ "/storage/books" ];
    serviceConfig.UMask = "0022";
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/syncthing 0700 paranas users -"
    "d /storage/books 0755 paranas users -"
  ];

  # Seed the folder once. Declaring it in settings.folders would overwrite the
  # devices selected in the GUI whenever syncthing-init runs.
  systemd.services.syncthing-books-init = {
    description = "Initialize the Syncthing books folder";
    wantedBy = [ "multi-user.target" ];
    requires = [ "syncthing-init.service" ];
    after = [ "syncthing-init.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "paranas";
      Group = "users";
    };
    script = ''
      ${pkgs.python3}/bin/python3 <<'PY'
      import json
      import urllib.request
      import xml.etree.ElementTree as ET

      key = ET.parse("${config.services.syncthing.configDir}/config.xml").findtext("gui/apikey")
      if not key:
          raise RuntimeError("Syncthing API key is missing")

      def request(path, data=None):
          req = urllib.request.Request(
              "http://127.0.0.1:8384/rest/config/" + path,
              data=None if data is None else json.dumps(data).encode(),
              headers={"X-API-Key": key, "Content-Type": "application/json"},
          )
          with urllib.request.urlopen(req, timeout=30) as response:
              body = response.read()
              return json.loads(body) if body else None

      folders = request("folders")
      if not any(f["id"] == "books" or f["path"].rstrip("/") == "/storage/books" for f in folders):
          folder = request("defaults/folder")
          folder.update(id="books", label="Books", path="/storage/books", type="sendreceive")
          request("folders", folder)
      PY
    '';
  };
}
