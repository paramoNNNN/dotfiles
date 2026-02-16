{
  services.immich = {
    enable = true;
    host = "0.0.0.0";
    port = 2283;
    openFirewall = true;
    mediaLocation = "/storage/photos";
    settings = {
      machineLearning = {
        enabled = true;
        urls = [
          "http://192.168.1.134:3003"
          "http://localhost:3003"
        ];
      };
    };
  };
}
