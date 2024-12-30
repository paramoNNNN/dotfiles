{ pkgs, ... }: {

  imports = [
    ./cmp.nix
    ./conform.nix
    ./dressing.nix
    ./gitpad.nix
    ./gitsigns.nix
    ./icons.nix
    ./indent-blankline.nix
    ./lazygit.nix
    ./lsp.nix
    ./lualine.nix
    ./mini.nix
    ./neo-tree.nix
    ./none-ls.nix
    ./notify.nix
    ./nui.nix
    ./package-info.nix
    ./persisted.nix
    ./presence.nix
    ./rainbow-delimiters.nix
    ./tailwind-tools.nix
    ./telescope.nix
    ./todo-comments.nix
    ./toggleterm.nix
    ./treesitter.nix
    ./ufo.nix
    ./undotree.nix
    ./which-key.nix
  ];

  programs.nixvim.extraPlugins = with pkgs.vimPlugins; [
    advanced-git-search-nvim
    promise-async
    tailwind-tools-nvim
    plenary-nvim
  ];
}
