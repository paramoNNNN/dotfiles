{
  private,
  pkgs,
  lib,
  ...
}:

let
  assets = lib.cleanSourceWith {
    src = ./home-controls;
    filter = path: _type: baseNameOf path != "__pycache__" && !(lib.hasSuffix ".pyc" path);
  };
  secrets = "/home/paranas/.local/share/paranas-home-secrets";
in
{
  systemd.services.paranas-home = {
    description = "Private living-room TV controls";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    environment.PYTHONDONTWRITEBYTECODE = "1";
    serviceConfig = {
      DynamicUser = true;
      LoadCredential = [
        "tv-key:${secrets}/tv_ed25519"
        "access-token:${secrets}/access-token"
      ];
      ExecStart = "${pkgs.python3}/bin/python3 ${assets}/server.py --origin https://home.${private.domain} --identity %d/tv-key --token-file %d/access-token --known-hosts ${assets}/tv_known_hosts --ssh ${pkgs.openssh}/bin/ssh";
      Restart = "on-failure";
      RestartSec = 5;
      UMask = "0077";
      NoNewPrivileges = true;
      PrivateTmp = true;
      PrivateDevices = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_UNIX"
      ];
      CapabilityBoundingSet = "";
      MemoryHigh = "64M";
      MemoryMax = "128M";
      TasksMax = 64;
    };
  };

  services.nginx.virtualHosts."home.${private.domain}".locations = {
    "= /tv".return = "301 /tv/";
    "/tv/" = {
      proxyPass = "http://127.0.0.1:8088";
      extraConfig = ''
        client_max_body_size 2k;
        proxy_read_timeout 90s;
        add_header X-Robots-Tag "noindex, nofollow" always;
      '';
    };
  };

  services.homepage-dashboard = {
    settings.layout."Living room" = {
      style = "row";
      columns = 1;
    };
    services = [
      {
        "Living room" = [
          {
            "TV Controls" = {
              href = "https://home.${private.domain}/tv/";
              icon = "mdi-television";
              description = "Power, AirPlay music, picture, inputs, and remote";
            };
          }
        ];
      }
    ];
  };
}
