{
  programs.nixvim.plugins.treesitter = {
    enable = true;
    settings = {
      ensure_installed =
        [ "javascript" "typescript" "tsx" "c" "lua" "vim" "vimdoc" "query" "astro" ];
      sync_install = false;
      auto_install = true;
      highlight = {
        enable = true;
        additional_vim_regex_highlighting = false;
      };
      autotag = { enable = true; };
    };
  };
}
