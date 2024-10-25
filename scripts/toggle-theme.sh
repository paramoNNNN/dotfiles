#!/bin/bash

MODE=${1}

ALACRITTY_CONFIG_PATH=~/.config/alacritty/alacritty.toml
TMUX_THEMES_PATH=~/.config/tmux/themes
LAZYGIT_CONFIG_PATH=~/.config/lazygit/config.yml
GITCONFIG_CONFIG_PATH=~/.config/.gitconfig
FISH_CONFIG_PATH=~/.config/fish/config.fish

function change_theme {
    if [ "$1" == "light" ]; then
        sed -i -e "s/catppuccin-mocha/catppuccin-latte/" $ALACRITTY_CONFIG_PATH
        sed -i -e "s/catppuccin-mocha/catppuccin-latte/" $GITCONFIG_CONFIG_PATH
        sed -i -e "s/Catppuccin Mocha/Catppuccin Latte/" $FISH_CONFIG_PATH
        sed -i -e "s/dark/light/" $LAZYGIT_CONFIG_PATH
        fish -c "set --universal theme light"
        tmux source-file "$TMUX_THEMES_PATH/light.conf"
        if [ "$(uname)" == "Darwin" ]; then
            osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to false'
        fi
    elif [ "$1" == "dark" ]; then
        sed -i -e "s/catppuccin-latte/catppuccin-mocha/" $ALACRITTY_CONFIG_PATH
        sed -i -e "s/catppuccin-latte/catppuccin-mocha/" $GITCONFIG_CONFIG_PATH
        sed -i -e "s/Catppuccin Latte/Catppuccin Mocha/" $FISH_CONFIG_PATH
        sed -i -e "s/light/dark/" $LAZYGIT_CONFIG_PATH
        fish -c "set --universal theme dark"
        tmux source-file "$TMUX_THEMES_PATH/dark.conf"
        if [ "$(uname)" == "Darwin" ]; then
            osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to true'
        fi
    fi
}

change_theme $MODE

exit
