alias ls "exa --icons"
alias go "git open"
alias docker-rm-all "sudo docker rm -f (sudo docker ps -a -q)"
alias nvim "nvim --listen /tmp/nvim-server-(tmux display-message -p '#S-#{window_index}').pipe"
alias cat "batcat --theme=base16"

fish_vi_key_bindings

source ~/.asdf/asdf.fish

# pnpm
set -gx PNPM_HOME "/Users/taha/Library/pnpm"
set -gx PATH "$PNPM_HOME" $PATH
# pnpm end

# tabtab source for packages
# uninstall by removing these lines
[ -f ~/.config/tabtab/fish/__tabtab.fish ]; and . ~/.config/tabtab/fish/__tabtab.fish; or true
