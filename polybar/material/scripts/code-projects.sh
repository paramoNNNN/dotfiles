#!/usr/bin/bash

# Path to the projects.json file (vscode alefragnani project manager)
SRC=~/.config/Code/User/globalStorage/alefragnani.project-manager/projects_cache_git.json

SDIR="$HOME/.config/polybar/material/scripts"

prj=$(jq -r "sort_by(.name) | .[].name" <$SRC | rofi -dmenu -p "VSCode Project Manager" -theme $SDIR/rofi/code-projects.rasi $@)

# If there was a selection, find its path from the src file and launch vscode.
if [ -n "$prj" ]; then
	prjpath=$(jq -r --arg prj "$prj" '.[] | select(.name==$prj) | .fullPath' <$SRC)
	code $prjpath
fi
