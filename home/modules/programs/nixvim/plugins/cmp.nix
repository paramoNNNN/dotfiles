{
  programs.nixvim.plugins = {
    friendly-snippets.enable = true;
    blink-cmp = {
      enable = true;
      settings = {
        signature = {
          enabled = false;
        };
        keymap = {
          preset = "enter";
        };
        completion = {
          menu = {
            border = "rounded";
          };
          documentation = { window = { border = "rounded"; }; };
        };
        sources = {
          cmdline = { __raw = ''{}''; };
          providers = {
            buffer = {
              score_offset = -7;
            };
          };
        };
      };
    };
  };
}
