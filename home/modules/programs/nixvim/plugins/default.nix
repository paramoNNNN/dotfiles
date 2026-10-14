{ pkgs, ... }:
{

  imports = [
    ./cmp.nix
    ./conform.nix
    ./gitsigns.nix
    ./icons.nix
    ./lazydocker.nix
    ./lazygit.nix
    ./lsp.nix
    ./lualine.nix
    ./mini.nix
    ./multicursor.nix
    ./neo-tree.nix
    ./lint.nix
    ./package-info.nix
    ./sidekick.nix
    ./telescope.nix
    ./todo-comments.nix
    ./toggleterm.nix
    ./treesitter.nix
    ./ts-autotag.nix
    ./ts-comments.nix
    ./undotree.nix
    ./which-key.nix
  ];

  programs.nixvim.opts.laststatus = 3;
  programs.nixvim.plugins.lz-n.enable = true;
  programs.nixvim.plugins.render-markdown = {
    enable = true;
    lazyLoad.settings.ft = [ "markdown" ];
    settings.file_types = [ "markdown" ];
  };

  programs.nixvim.extraPlugins = with pkgs.vimPlugins; [
    advanced-git-search-nvim
  ];
}
