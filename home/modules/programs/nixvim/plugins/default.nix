{ pkgs, ... }:
{

  imports = [
    ./avante.nix
    ./cmp.nix
    ./conform.nix
    ./gitsigns.nix
    ./icons.nix
    ./lazydocker.nix
    ./lazygit.nix
    ./lsp.nix
    ./lualine.nix
    ./luasnip.nix
    ./mini.nix
    ./multicursor.nix
    ./neo-tree.nix
    ./none-ls.nix
    ./nui.nix
    ./package-info.nix
    ./platformio.nix
    ./rainbow-delimiters.nix
    ./telescope.nix
    ./todo-comments.nix
    ./toggleterm.nix
    ./treesitter.nix
    ./ts-autotag.nix
    ./ts-comments.nix
    ./ufo.nix
    ./undotree.nix
    ./which-key.nix
  ];

  programs.nixvim.extraPlugins = with pkgs.vimPlugins; [
    advanced-git-search-nvim
    promise-async
  ];
}
