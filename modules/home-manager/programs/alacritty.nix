{
  env = { "TERM" = "xterm-256color"; };

  scrolling = { history = 10000; };

  window = {
    padding = {
      x = 10;
      y = 0;
    };
    opacity = 0.9;
    decorations = "None";
  };

  font = {
    size = 16.0;
    glyph_offset.y = 5;
    offset.y = 2;

    normal.family = "CaskaydiaCove Nerd Font";
    bold = {
      family = "CaskaydiaCove Nerd Font";
      style = "SemiBold";
    };
    italic.family = "CaskaydiaCove Nerd Font";
  };

  cursor = {
    style = "Block";
    unfocused_hollow = false;
  };

  shell = { program = "fish"; };
}

