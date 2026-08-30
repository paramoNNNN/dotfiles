{ pkgs, ... }:

let
  bridgeRevision = "c3760beaa0851214da4860903445d7f6420ca025";
  bridgeApp = "/var/lib/obsidian-livesync-bridge/app-${bridgeRevision}";
  bridgeSource = pkgs.fetchFromGitHub {
    owner = "vrtmrz";
    repo = "livesync-bridge";
    rev = bridgeRevision;
    hash = "sha256-btLnQNbFzCPaSVcY9rtiPdYeXrZjoK9AYvfA9+ovsIc=";
  };

  bridgeConfig = pkgs.writeShellScript "configure-obsidian-livesync-bridge" ''
    set -eu

    : "''${COUCHDB_DATABASE:?Set COUCHDB_DATABASE in /var/lib/obsidian-bridge-secrets/environment}"
    : "''${COUCHDB_USERNAME:?Set COUCHDB_USERNAME in /var/lib/obsidian-bridge-secrets/environment}"
    : "''${COUCHDB_PASSWORD:?Set COUCHDB_PASSWORD in /var/lib/obsidian-bridge-secrets/environment}"

    ${pkgs.jq}/bin/jq -n \
      --arg database "$COUCHDB_DATABASE" \
      --arg username "$COUCHDB_USERNAME" \
      --arg password "$COUCHDB_PASSWORD" \
      --arg passphrase "''${LIVESYNC_PASSPHRASE:-}" \
      --arg obfuscatePassphrase "''${LIVESYNC_OBFUSCATE_PASSPHRASE:-}" \
      '{ peers: [
        {
          type: "couchdb",
          name: "obsidian-couchdb",
          group: "main",
          database: $database,
          username: $username,
          password: $password,
          url: "http://127.0.0.1:5984",
          baseDir: "",
          passphrase: $passphrase,
          obfuscatePassphrase: $obfuscatePassphrase,
          useRemoteTweaks: true,
          includeInternal: []
        },
        {
          type: "storage",
          name: "server-vault",
          group: "main",
          baseDir: "/var/lib/obsidian-vault/",
          scanOfflineChanges: true,
          useChokidar: true
        }
      ] }' > /var/lib/obsidian-livesync-bridge/config.json
  '';

  seedVault = pkgs.writeShellScript "seed-obsidian-vault" ''
    set -eu
    ${pkgs.coreutils}/bin/mkdir -p /var/lib/obsidian-vault
    ${pkgs.coreutils}/bin/cp -Rn ${./obsidian-vault}/. /var/lib/obsidian-vault/
    ${pkgs.coreutils}/bin/chown -R root:obsidian-vault /var/lib/obsidian-vault
    ${pkgs.coreutils}/bin/chmod -R u+rwX,g+rwX,o-rwx /var/lib/obsidian-vault
  '';
in
{
  users.groups.obsidian-vault = { };

  systemd.tmpfiles.rules = [
    "d /var/lib/obsidian-vault 0770 root obsidian-vault -"
  ];

  systemd.services.obsidian-livesync-bridge = {
    description = "Self-hosted LiveSync CouchDB to Markdown bridge";
    documentation = [ "https://github.com/vrtmrz/livesync-bridge" ];
    wantedBy = [ "multi-user.target" ];
    after = [
      "couchdb.service"
      "network-online.target"
    ];
    wants = [
      "couchdb.service"
      "network-online.target"
    ];

    unitConfig.ConditionPathExists = "/var/lib/obsidian-bridge-secrets/environment";

    preStart = ''
      mkdir -p ${bridgeApp}
      cp -R ${bridgeSource}/. ${bridgeApp}/
      chmod -R u+w ${bridgeApp}
      cd ${bridgeApp}
      ${pkgs.deno}/bin/deno install --frozen
      ${bridgeConfig}
      ln -sf /var/lib/obsidian-livesync-bridge/config.json dat/config.json
    '';

    script = ''
      cd ${bridgeApp}
      exec ${pkgs.deno}/bin/deno task run
    '';

    serviceConfig = {
      DynamicUser = true;
      User = "obsidian-livesync-bridge";
      SupplementaryGroups = [ "obsidian-vault" ];
      EnvironmentFile = "/var/lib/obsidian-bridge-secrets/environment";
      Environment = "DENO_DIR=/var/lib/obsidian-livesync-bridge/deno-cache";
      StateDirectory = "obsidian-livesync-bridge";
      StateDirectoryMode = "0750";
      UMask = "0007";
      Restart = "on-failure";
      RestartSec = "10s";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ReadWritePaths = [
        "/var/lib/obsidian-livesync-bridge"
        "/var/lib/obsidian-vault"
      ];
    };
  };

  # Run explicitly after the first mirror completes. Existing files are kept.
  systemd.services.obsidian-vault-seed = {
    description = "Copy the versioned Obsidian starter vault into the LiveSync mirror";
    after = [ "obsidian-livesync-bridge.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    script = "exec ${seedVault}";
  };
}
