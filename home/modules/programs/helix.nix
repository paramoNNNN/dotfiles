{ pkgs, ... }:
{
  programs.helix = {
    enable = true;
    settings.editor.line-number = "relative";

    extraPackages = with pkgs; [
      nil
      nixfmt
      nodejs
      typescript
      typescript-language-server
      vscode-langservers-extracted
      tailwindcss-language-server
      astro-language-server
      dockerfile-language-server
      yaml-language-server
      lua-language-server
      bash-language-server
      pyright
      black
      prettier
      stylua
      shfmt
      fish
    ];
  };
}
