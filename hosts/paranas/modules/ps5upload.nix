{ private, pkgs, ... }:

let
  ps5Address = "192.168.1.176";
  hostAddress = "192.168.1.215";
  tailscaleIPv4 = "100.64.0.3";
  tailscaleIPv6 = "fd7a:115c:a1e0::3";
  outputDirectory = "/storage/share/PS5/First Light/converted";
in
{
  # Use the same rootless daemon and named volume as the manual container.
  users.users.paranas.linger = true;
  systemd.user.services.ps5upload-engine = {
    description = "PS5 Upload engine and web UI";
    wantedBy = [ "default.target" ];
    requires = [ "docker.service" ];
    after = [ "docker.service" ];
    unitConfig = {
      ConditionUser = "paranas";
      StartLimitIntervalSec = 0;
    };
    environment = {
      DOCKER_HOST = "unix://%t/docker.sock";
      PS5_ADDR = ps5Address;
      PS5UPLOAD_PKG_HOST_IP = hostAddress;
      PS5UPLOAD_ALLOW_IP = "192.168.1.0/24,100.64.0.0/10,fd7a:115c:a1e0::/48";
      PS5UPLOAD_BROWSE_ROOTS = "/games,/output,/hdd-ps5";
    };
    preStart = ''
      ${pkgs.util-linux}/bin/mountpoint -q /storage
      ${pkgs.coreutils}/bin/mkdir -p "${outputDirectory}"
      ${pkgs.docker}/bin/docker rm -f ps5upload-engine || true
    '';
    script = ''
      extraMounts=()
      if [ -d /mnt/hdd/PS5 ]; then
        extraMounts+=(--mount type=bind,source=/mnt/hdd/PS5,target=/hdd-ps5)
      fi
      exec ${pkgs.docker}/bin/docker run --rm --name ps5upload-engine \
        --network host \
        --env PS5_ADDR --env PS5UPLOAD_PKG_HOST_IP \
        --env PS5UPLOAD_ALLOW_IP --env PS5UPLOAD_BROWSE_ROOTS \
        --volume ps5upload-data:/data \
        --mount type=bind,source=/storage/share/PS5,target=/games,readonly \
        --mount "type=bind,source=${outputDirectory},target=/output" \
        "''${extraMounts[@]}" \
        ghcr.io/phantomptr/ps5upload-engine-webui:latest
    '';
    serviceConfig = {
      Restart = "always";
      RestartSec = 5;
      TimeoutStartSec = 0;
      TimeoutStopSec = 45;
      ExecStop = "${pkgs.docker}/bin/docker stop --time 30 ps5upload-engine";
      ExecStopPost = "-${pkgs.docker}/bin/docker rm -f ps5upload-engine";
    };
  };

  # Direct access is limited to the home LAN and the Tailscale interface.
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 19113 ];
  networking.firewall.extraCommands = ''
    iptables -w -A nixos-fw -i enp1s0 -s 192.168.1.0/24 -p tcp --dport 19113 -j nixos-fw-accept
  '';
  networking.firewall.extraStopCommands = ''
    iptables -w -D nixos-fw -i enp1s0 -s 192.168.1.0/24 -p tcp --dport 19113 -j nixos-fw-accept 2>/dev/null || true
  '';

  services.nginx.virtualHosts."ps5.${private.domain}" = {
    useACMEHost = "${private.domain}";
    forceSSL = true;
    # clipboard.nix guards Tailscale destinations; restrict LAN clients here too.
    extraConfig = ''
      if ($server_addr !~ "^(192[.]168[.]1[.]215|100[.]64[.]0[.]3|${tailscaleIPv6})$") { return 403; }
      allow 192.168.1.0/24;
      allow 100.64.0.0/10;
      allow fd7a:115c:a1e0::/48;
      deny all;
      client_max_body_size 0;
      add_header X-Robots-Tag "noindex, nofollow" always;
    '';
    locations."/" = {
      proxyPass = "http://127.0.0.1:19113";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
        proxy_buffering off;
        proxy_request_buffering off;
      '';
    };
  };
  security.acme.certs."${private.domain}".extraDomainNames = [ "ps5.${private.domain}" ];
}
