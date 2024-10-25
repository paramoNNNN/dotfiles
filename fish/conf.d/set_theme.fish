function update_theme --on-variable theme
    if [ "$theme" = dark ]
        fish_config theme save catppuccin-mocha
        set --universal pure_color_system_time white
    else if [ "$theme" = light ]
        fish_config theme save catppuccin-latte
        set --universal pure_color_system_time black
    end
end
