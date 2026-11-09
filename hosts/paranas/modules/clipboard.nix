{ private, pkgs, ... }:

let
  # Keep these in sync with this host's Headscale node addresses.
  tailscaleIPv4 = "100.64.0.3";
  tailscaleIPv6 = "fd7a:115c:a1e0::3";
  guardRules = pkgs.writeText "clipboard-guard.nft" ''
    table inet clipboard_guard {
      chain input {
        type filter hook input priority -10; policy accept;
        iifname != { "tailscale0", "lo" } ip daddr ${tailscaleIPv4} tcp dport { 80, 443 } drop
        iifname != { "tailscale0", "lo" } ip6 daddr ${tailscaleIPv6} tcp dport { 80, 443 } drop
      }
    }
  '';
in
{
  services.microbin = {
    enable = true;
    passwordFile = "/var/lib/microbin-secrets/environment";
    settings = {
      MICROBIN_BIND = "127.0.0.1";
      MICROBIN_PORT = 8045;
      MICROBIN_DATA_DIR = "/var/lib/microbin/data";
      MICROBIN_PUBLIC_PATH = "https://clipboard.${private.domain}";
      MICROBIN_TITLE = "Clipboard";
      MICROBIN_THREADS = 1;
      MICROBIN_EDITABLE = true;
      MICROBIN_NO_LISTING = false;
      MICROBIN_NO_FILE_UPLOAD = false;
      MICROBIN_DEFAULT_EXPIRY = "1week";
      MICROBIN_MAX_EXPIRY = "never";
      MICROBIN_ETERNAL_PASTA = true;
      # Do not silently remove items explicitly saved with no expiry.
      MICROBIN_GC_DAYS = 0;
      MICROBIN_MAX_FILE_SIZE_UNENCRYPTED_MB = 100;
      MICROBIN_MAX_FILE_SIZE_ENCRYPTED_MB = 25;
      MICROBIN_QR = true;
      MICROBIN_DISABLE_TELEMETRY = true;
      MICROBIN_DISABLE_UPDATE_CHECKING = true;
      MICROBIN_LIST_SERVER = false;
    };
  };

  # Generate a persistent admin password without putting it in the Nix store.
  systemd.services.microbin-secrets = {
    description = "Initialize MicroBin admin credentials";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      StateDirectory = "microbin-secrets";
      StateDirectoryMode = "0700";
      UMask = "0077";
    };
    script = ''
      if [ ! -s /var/lib/microbin-secrets/environment ]; then
        password=$(${pkgs.openssl}/bin/openssl rand -hex 32)
        printf 'MICROBIN_ADMIN_USERNAME=admin\nMICROBIN_ADMIN_PASSWORD=%s\n' "$password" \
          > /var/lib/microbin-secrets/environment
      fi
    '';
  };
  systemd.services.microbin = {
    requires = [ "microbin-secrets.service" ];
    after = [ "microbin-secrets.service" ];
    serviceConfig = {
      UMask = "0077";
      MemoryHigh = "256M";
      MemoryMax = "512M";
    };
  };

  # CGNAT source addresses also occur on the ISP network, so an nginx source
  # CIDR allowlist alone cannot prove a connection arrived through Tailscale.
  # Guard HTTPS to the tail addresses; other nginx hosts keep their listeners.
  systemd.services.clipboard-guard = {
    description = "Require Tailscale ingress for private web addresses";
    wantedBy = [ "multi-user.target" ];
    after = [ "firewall.service" ];
    before = [ "nginx.service" ];
    restartTriggers = [ guardRules ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.nftables}/bin/nft -f ${guardRules}";
      ExecStop = "${pkgs.nftables}/bin/nft delete table inet clipboard_guard";
      CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
    };
  };
  systemd.services.nginx = {
    requires = [ "clipboard-guard.service" ];
    after = [ "clipboard-guard.service" ];
  };
  services.nginx.virtualHosts."clipboard.${private.domain}" = {
    useACMEHost = "${private.domain}";
    forceSSL = true;
    # Reject this hostname on public/LAN destination addresses, even when a
    # caller supplies a forged Host header or TLS SNI name.
    extraConfig = ''
      if ($server_addr !~ "^(100[.]64[.]0[.]3|${tailscaleIPv6})$") { return 403; }
      client_max_body_size 110M;
      add_header X-Robots-Tag "noindex, nofollow" always;
    '';
    locations."/" = {
      proxyPass = "http://127.0.0.1:8045";
      extraConfig = ''
        proxy_read_timeout 300s;
        proxy_send_timeout 300s;
      '';
    };
  };
  security.acme.certs."${private.domain}".extraDomainNames = [ "clipboard.${private.domain}" ];
}
