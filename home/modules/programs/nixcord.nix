{ inputs, ... }: {
  imports = [ inputs.nixcord.homeModules.nixcord ];
  programs.nixcord = {
    enable = true;
    discord.enable = true;
    config.plugins = {
      betterSettings.enable = true;
      colorSighted.enable = true;
      fakeNitro.enable = true;
      fixYoutubeEmbeds.enable = true;
      friendsSince.enable = true;
      memberCount.enable = true;
      messageLatency.enable = true;
      petpet.enable = true;
      betterFolders = {
        enable = true;
        closeAllFolders = true;
        closeAllHomeButton = true;
        closeOthers = true;
        forceOpen = true;
      };
    };
  };

  stylix.targets.nixcord.extraCss = ''
    .visual-refresh {
      .chatContent_f75fb0 {
        background-color: red !important;
      }
    }
  '';
}

