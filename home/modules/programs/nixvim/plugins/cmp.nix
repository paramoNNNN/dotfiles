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
            auto_show = {
              __raw = ''
                function(ctx)
                  return ctx.mode ~= "cmdline" or not vim.tbl_contains({ '/', '?', ':' }, vim.fn.getcmdtype())
                end
              '';
            };
          };
          documentation = { window = { border = "rounded"; }; };
        };
        sources = {
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
