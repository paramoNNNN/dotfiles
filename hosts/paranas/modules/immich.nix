{
  services.immich = {
    enable = true;
    host = "0.0.0.0";
    port = 2283;
    openFirewall = true;
    mediaLocation = "/storage/photos";
    settings = {
      job = {
        backgroundTask = {
          concurrency = 1;
        };
        faceDetection = {
          concurrency = 1;
        };
        library = {
          concurrency = 1;
        };
        metadataExtraction = {
          concurrency = 1;
        };
        migration = {
          concurrency = 1;
        };
        notifications = {
          concurrency = 1;
        };
        ocr = {
          concurrency = 1;
        };
        search = {
          concurrency = 1;
        };
        sidecar = {
          concurrency = 1;
        };
        smartSearch = {
          concurrency = 2;
        };
        thumbnailGeneration = {
          concurrency = 1;
        };
        videoConversion = {
          concurrency = 1;
        };
      };
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
