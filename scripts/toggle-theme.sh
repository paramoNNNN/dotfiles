#!/bin/bash
ALACRITTY_CONFIG_PATH=~/.config/alacritty/alacritty.yml
KITTY_CONFIG_FOLDER=~/.config/kitty
TMUX_THEMES_PATH=~/.config/tmux/themes
THEME=$(defaults read -g AppleInterfaceStyle 2>/dev/null)

notify() {
	osascript -e "display notification \"${1}\" with title \"alacritty-theme-toggle\" subtitle \"Switched alacritty theme:\""
}

if [ "$THEME" == "Dark" ]; then
	sed -i -e "s/carbonfox/catppuccin-latte/" $ALACRITTY_CONFIG_PATH &&
		sed -i -e "s/carbonfox/catppuccin-latte/" "$KITTY_CONFIG_FOLDER/kitty.conf" &&
		kitty @ set-colors -a "$KITTY_CONFIG_FOLDER/themes/catppuccin-latte.conf" &&
		fish -c "set --universal theme light" &&
		tmux source-file "$TMUX_THEMES_PATH/light.conf" &&
		osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to false' &&
		notify "light" &&
		exit
else
	sed -i -e "s/catppuccin-latte/carbonfox/" $ALACRITTY_CONFIG_PATH &&
		sed -i -e "s/catppuccin-latte/carbonfox/" "$KITTY_CONFIG_FOLDER/kitty.conf" &&
		kitty @ set-colors -a "$KITTY_CONFIG_FOLDER/themes/carbonfox.conf" &&
		fish -c "set --universal theme light" &&
		fish -c "set --universal theme dark" &&
		tmux source-file "$TMUX_THEMES_PATH/dark.conf" &&
		osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to true' &&
		notify "dark" &&
		exit
fi
