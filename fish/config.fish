
alias ls "exa --icons"
alias go "git open"
alias nano "vim"
alias docker-rm-all "sudo docker rm -f (sudo docker ps -a -q)"
alias nvim "nvim --listen /tmp/nvim-server-(tmux display-message -p '#S-#{window_index}').pipe"
alias vim "nvim"

fish_vi_key_bindings

source ~/.asdf/asdf.fish

# Nightfox Color Palette
# Style: carbonfox
# Upstream: https://github.com/edeneast/nightfox.nvim/raw/main/extra/carbonfox/nightfox_fish.fish
set -l foreground f2f4f8
set -l selection 2a2a2a
set -l comment 6e6f70
set -l red ee5396
set -l orange 3ddbd9
set -l yellow 08bdba
set -l green 25be6a
set -l purple be95ff
set -l cyan 33b1ff
set -l pink ff7eb6

# Syntax Highlighting Colors
set -g fish_color_normal $foreground
set -g fish_color_command $cyan
set -g fish_color_keyword $pink
set -g fish_color_quote $yellow
set -g fish_color_redirection $foreground
set -g fish_color_end $orange
set -g fish_color_error $red
set -g fish_color_param $purple
set -g fish_color_comment $comment
set -g fish_color_selection --background=$selection
set -g fish_color_search_match --background=$selection
set -g fish_color_operator $green
set -g fish_color_escape $pink
set -g fish_color_autosuggestion $comment

# Completion Pager Colors
set -g fish_pager_color_progress $comment
set -g fish_pager_color_prefix $cyan
set -g fish_pager_color_completion $foreground
set -g fish_pager_color_description $comment

# Pure Colors
set -g pure_color_mute $comment

# pnpm
set -gx PNPM_HOME "/home/taha/.local/share/pnpm"
set -gx PATH "$PNPM_HOME" $PATH
# pnpm end

set PATH $PATH ~/.cargo/bin

# tabtab source for packages
# uninstall by removing these lines
[ -f ~/.config/tabtab/fish/__tabtab.fish ]; and . ~/.config/tabtab/fish/__tabtab.fish; or true
