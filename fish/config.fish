_pure_set_default pure_show_system_time true
_pure_set_default pure_color_system_time white

alias ls "exa --icons"
alias go "git open"
alias nano "vim"
alias docker-rm-all "sudo docker rm -f (sudo docker ps -a -q)"

fish_vi_key_bindings

source ~/.asdf/asdf.fish

# pnpm
set -gx PNPM_HOME "/home/taha/.local/share/pnpm"
set -gx PATH "$PNPM_HOME" $PATH
# pnpm end

set PATH $PATH ~/.cargo/bin

# tabtab source for packages
# uninstall by removing these lines
[ -f ~/.config/tabtab/fish/__tabtab.fish ]
and . ~/.config/tabtab/fish/__tabtab.fish
or true
