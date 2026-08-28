{ pkgs, ... }: {
  programs.nixvim = {
    extraPackages = with pkgs; [
      ripgrep
      fd
      curl
      gnutar
      codex-acp
    ];
    opts.laststatus = 3;

    plugins = {
      avante = {
        enable = true;
        settings = {
          provider = "codex";
          auto_suggestions_provider = "codex";
          mode = "agentic";
          acp_providers = {
            codex = {
              command = "pnpx";
              args = [ "@agentclientprotocol/codex-acp" ];
              env = {
                NODE_NO_WARNINGS = "1";
              };
            };
          };
          instructions_file = "avante.md";

          windows = {
            position = "right";
            input.height = 12;
          };
        };
      };

      render-markdown = {
        enable = true;
        settings.file_types = [
          "markdown"
          "Avante"
        ];
      };
    };

  };
}
