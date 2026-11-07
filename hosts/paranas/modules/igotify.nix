{ ... }:

{
  virtualisation.oci-containers.containers.igotify = {
    image = "ghcr.io/androidseb25/igotify-notification-assist:v1.6.0.1@sha256:a44de0b94322a30c8a4af883ed28061f01cda8e5d10f0c52e10b278dc4ac79c4";
    environmentFiles = [ "/var/lib/igotify-secrets/environment" ];
    environment = {
      ASPNETCORE_URLS = "http://127.0.0.1:8044";
      ENABLE_SCALAR_UI = "false";
      ENABLE_USER_UI = "false";
    };
    volumes = [ "/var/lib/igotify:/app/data" ];
    # Gotify listens on the host's loopback interface. The assistant API also
    # stays on loopback; Local Instance pairing uses the protected env file.
    extraOptions = [
      "--network=host"
      "--memory=256m"
      "--cpus=0.5"
      "--cap-drop=ALL"
      "--security-opt=no-new-privileges"
    ];
  };

  systemd.services.docker-igotify = {
    after = [ "gotify-server.service" ];
    wants = [ "gotify-server.service" ];
    unitConfig.ConditionPathExists = "/var/lib/igotify-secrets/environment";
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/igotify 0700 root root -"
    "d /var/lib/igotify-secrets 0700 root root -"
  ];
}
