{ pkgs, ... }: {
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [ tailwind-tools-nvim ];

    autoCmd = [{
      command = "TailwindSort";
      event = "BufWritePre";
      pattern = "*.tsx";
    }];

    extraConfigLuaPost = ''
      require("tailwind-tools").setup({});
    '';
  };
}
