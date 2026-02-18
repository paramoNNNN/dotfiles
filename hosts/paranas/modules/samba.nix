{
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "paranas";
        "netbios name" = "paranas";
        "security" = "user";
        "hosts allow" = "192.168.0. 127.0.0.1 localhost 192.168.1. 100.0.0.0/8";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };
      "Share" = {
        "path" = "/storage/share";
        "browseable" = "yes";
        "writeable" = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0600";
        "directory mask" = "0700";
        "force user" = "paranas";
      };
      "Movies" = {
        "path" = "/storage/media/Movies";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0600";
        "directory mask" = "0700";
        "force user" = "paranas";
      };
      "Music" = {
        "path" = "/storage/media/Music";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0600";
        "directory mask" = "0700";
        "force user" = "paranas";
      };
      "TV Shows" = {
        "path" = "/storage/media/TV Shows";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0600";
        "directory mask" = "0700";
        "force user" = "paranas";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };
}
