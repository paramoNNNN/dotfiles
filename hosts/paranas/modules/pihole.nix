{ private, pkgs, ... }:

let
  lanAddress = "192.168.1.215";
  lanSubnet = "192.168.1.0/24";
in
{
  services.pihole-ftl = {
    enable = true;
    # DNS is allowed only from the LAN below, never opened globally.
    openFirewallDNS = false;
    openFirewallDHCP = false;
    openFirewallWebserver = false;
    lists = [
      {
        url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
        description = "StevenBlack unified hosts";
      }
    ];
    settings = {
      dns = {
        EDNS0ECS = true;
        # Resolve client names through OpenWrt, without a DNS upstream loop.
        revServers = [
          "true,192.168.1.0/24,192.168.1.1,lan"
          "true,fd4f:178a:3acc::/60,192.168.1.1,lan"
          "true,100.64.0.0/10,100.100.100.100,tn.${private.domain}"
          "true,fd7a:115c:a1e0::/48,100.100.100.100,tn.${private.domain}"
        ];
        upstreams = [
          "1.1.1.1"
          "1.0.0.1"
        ];
        # Bind explicit addresses so resolved keeps 127.0.0.53/54:53.
        listeningMode = "NONE";
        hosts = [ "${lanAddress} pi.${private.domain}" ];
      };
      misc.dnsmasq_lines = [
        "bind-dynamic"
        "listen-address=127.0.0.1,${lanAddress}"
      ];
      dhcp.active = false;
      database.maxDBdays = 30;
    };
  };

  services.pihole-web = {
    enable = true;
    hostName = "pi.${private.domain}";
    ports = [
      "127.0.0.1:8053"
      "${lanAddress}:8053"
    ];
  };

  # Generate credentials at activation time, outside the repository/Nix store.
  systemd.services.pihole-secrets = {
    description = "Initialize Pi-hole dashboard password";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      StateDirectory = "pihole-secrets";
      StateDirectoryMode = "0700";
      UMask = "0077";
    };
    script = ''
      if [ ! -s /var/lib/pihole-secrets/environment ]; then
        password=$(${pkgs.openssl}/bin/openssl rand -hex 24)
        printf 'FTLCONF_webserver_api_password=%s\n' "$password" \
          > /var/lib/pihole-secrets/environment
      fi
    '';
  };
  systemd.services.pihole-ftl = {
    requires = [ "pihole-secrets.service" ];
    after = [
      "pihole-secrets.service"
      "network-online.target"
    ];
    wants = [ "network-online.target" ];
    serviceConfig.EnvironmentFile = "/var/lib/pihole-secrets/environment";
  };
  systemd.timers.pihole-gravity = {
    description = "Refresh Pi-hole blocklists daily";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      RandomizedDelaySec = "1h";
      Persistent = true;
      Unit = "pihole-ftl-setup.service";
    };
  };

  networking.firewall.extraCommands = ''
    iptables -A nixos-fw -i enp1s0 -s ${lanSubnet} -d ${lanAddress} -p tcp -m multiport --dports 53,8053 -j nixos-fw-accept
    iptables -A nixos-fw -i enp1s0 -s ${lanSubnet} -d ${lanAddress} -p udp --dport 53 -j nixos-fw-accept
  '';

  services.nginx.virtualHosts."pi.${private.domain}" = {
    useACMEHost = "${private.domain}";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8053";
      proxyWebsockets = true;
    };
  };
  security.acme.certs."${private.domain}".extraDomainNames = [ "pi.${private.domain}" ];
}
