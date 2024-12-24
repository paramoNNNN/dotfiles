{
  programs.lazygit = {
    enable = true;
    settings = {
      git = {
        paging = {
          colorArg = "always";
          pager = "delta --paging=never --24-bit-color=never";
        };
      };
      os = {
        edit = ''
          nvim --server /tmp/nvim-server-$(tmux display-message -p '#S-#{window_index}').pipe --remote-send "<cmd>lua require('scripts.lazygit-open-file')('{{filename}}', '{{line}}')<CR>"'';
        open = ''
          nvim --server /tmp/nvim-server-$(tmux display-message -p '#S-#{window_index}').pipe --remote-send "<cmd>lua require('scripts.lazygit-open-file')('{{filename}}', '{{line}}')<CR>"'';
      };
    };
  };
}
