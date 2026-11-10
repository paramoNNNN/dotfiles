{ pkgs, private, ... }:

{
  environment.systemPackages = [ pkgs.rendercv ];
  fonts.packages = [ pkgs.raleway ];

  systemd.services.rendercv-editor = {
    description = "RenderCV web editor";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    environment = {
      HOME = "/var/lib/rendercv-editor";
      XDG_CACHE_HOME = "/var/cache/rendercv-editor";
    };
    serviceConfig = {
      ExecStart = "${pkgs.python3}/bin/python3 ${./rendercv/server.py} --data /var/lib/rendercv-editor --seed ${../../../cv/Taha_Ojari_CV.yaml} --html ${./rendercv/index.html} --rendercv ${pkgs.rendercv}/bin/rendercv";
      DynamicUser = true;
      StateDirectory = "rendercv-editor";
      StateDirectoryMode = "0700";
      CacheDirectory = "rendercv-editor";
      WorkingDirectory = "/var/lib/rendercv-editor";
      UMask = "0077";
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      PrivateDevices = true;
      NoNewPrivileges = true;
      RestrictSUIDSGID = true;
      Restart = "on-failure";
      MemoryMax = "1G";
      TasksMax = 128;
    };
  };

  services.nginx.virtualHosts."cv.${private.domain}" = {
    useACMEHost = private.domain;
    forceSSL = true;
    # The clipboard module's ingress guard protects these Tailscale addresses.
    extraConfig = ''
      if ($server_addr !~ "^(100[.]64[.]0[.]3|fd7a:115c:a1e0::3)$") { return 403; }
      client_max_body_size 256k;
      add_header X-Robots-Tag "noindex, nofollow" always;
    '';
    locations."/" = {
      proxyPass = "http://127.0.0.1:8047";
      extraConfig = ''
        proxy_read_timeout 120s;
      '';
    };
  };
  security.acme.certs."${private.domain}".extraDomainNames = [ "cv.${private.domain}" ];
  services.headscale.settings.dns.extra_records = [
    {
      name = "cv.${private.domain}";
      type = "A";
      value = "100.64.0.3";
    }
  ];
}
