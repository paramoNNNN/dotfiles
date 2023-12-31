function update_theme --on-variable theme
    if [ "$theme" = "dark" ]
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
        set --universal pure_color_system_time white
    else if [ "$theme" = "light" ]
        set -g fish_color_normal 4c4f69
        set -g fish_color_command 1e66f5
        set -g fish_color_param dd7878
        set -g fish_color_keyword d20f39
        set -g fish_color_quote 40a02b
        set -g fish_color_redirection ea76cb
        set -g fish_color_end fe640b
        set -g fish_color_comment 8c8fa1
        set -g fish_color_error d20f39
        set -g fish_color_gray 9ca0b0
        set -g fish_color_selection --background=ccd0da
        set -g fish_color_search_match --background=ccd0da
        set -g fish_color_option 40a02b
        set -g fish_color_operator ea76cb
        set -g fish_color_escape e64553
        set -g fish_color_autosuggestion 9ca0b0
        set -g fish_color_cancel d20f39
        set -g fish_color_cwd df8e1d
        set -g fish_color_user 179299
        set -g fish_color_host_remote 40a02b
        set -g fish_color_host 1e66f5
        set -g fish_color_status d20f39
        set -g fish_pager_color_progress 9ca0b0
        set -g fish_pager_color_prefix ea76cb
        set -g fish_pager_color_completion 4c4f69
        set -g fish_pager_color_description 9ca0b0
        set --universal pure_color_system_time black
    end
end
