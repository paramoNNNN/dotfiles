{
  programs.wofi = {
    enable = true;
    settings = {
      show = "drun";
      width = 750;
      height = 500;
      always_parse_args = true;
      show_all = false;
      term = "ghostty";
      hide_scroll = true;
      print_command = true;
      insensitive = true;
      columns = 2;
    };

    # mocha
    # @define-color	rosewater  #f5e0dc;
    # @define-color	rosewater-rgb  rgb(245, 224, 220);
    # @define-color	flamingo  #f2cdcd;
    # @define-color	flamingo-rgb  rgb(242, 205, 205);
    # @define-color	pink  #f5c2e7;
    # @define-color	pink-rgb  rgb(245, 194, 231);
    # @define-color	mauve  #cba6f7;
    # @define-color	mauve-rgb  rgb(203, 166, 247);
    # @define-color	red  #f38ba8;
    # @define-color	red-rgb  rgb(243, 139, 168);
    # @define-color	maroon  #eba0ac;
    # @define-color	maroon-rgb  rgb(235, 160, 172);
    # @define-color	peach  #fab387;
    # @define-color	peach-rgb  rgb(250, 179, 135);
    # @define-color	yellow  #f9e2af;
    # @define-color	yellow-rgb  rgb(249, 226, 175);
    # @define-color	green  #a6e3a1;
    # @define-color	green-rgb  rgb(166, 227, 161);
    # @define-color	teal  #94e2d5;
    # @define-color	teal-rgb  rgb(148, 226, 213);
    # @define-color	sky  #89dceb;
    # @define-color	sky-rgb  rgb(137, 220, 235);
    # @define-color	sapphire  #74c7ec;
    # @define-color	sapphire-rgb  rgb(116, 199, 236);
    # @define-color	blue  #89b4fa;
    # @define-color	blue-rgb  rgb(137, 180, 250);
    # @define-color	lavender  #b4befe;
    # @define-color	lavender-rgb  rgb(180, 190, 254);
    # @define-color	text  #cdd6f4;
    # @define-color	text-rgb  rgb(205, 214, 244);
    # @define-color	subtext1  #bac2de;
    # @define-color	subtext1-rgb  rgb(186, 194, 222);
    # @define-color	subtext0  #a6adc8;
    # @define-color	subtext0-rgb  rgb(166, 173, 200);
    # @define-color	overlay2  #9399b2;
    # @define-color	overlay2-rgb  rgb(147, 153, 178);
    # @define-color	overlay1  #7f849c;
    # @define-color	overlay1-rgb  rgb(127, 132, 156);
    # @define-color	overlay0  #6c7086;
    # @define-color	overlay0-rgb  rgb(108, 112, 134);
    # @define-color	surface2  #585b70;
    # @define-color	surface2-rgb  rgb(88, 91, 112);
    # @define-color	surface1  #45475a;
    # @define-color	surface1-rgb  rgb(69, 71, 90);
    # @define-color	surface0  #313244;
    # @define-color	surface0-rgb  rgb(49, 50, 68);
    # @define-color	base  #11111b;
    # @define-color	base-rgb  rgb(30, 30, 46);
    # @define-color	mantle  #181825;
    # @define-color	mantle-rgb  rgb(24, 24, 37);
    # @define-color	crust  #11111b;
    # @define-color	crust-rgb  rgb(17, 17, 27);

    style = ''
      @define-color	rosewater  #dc8a78;
      @define-color	rosewater-rgb  rgb(220, 138, 120);
      @define-color	flamingo  #dd7878;
      @define-color	flamingo-rgb  rgb(221, 120, 120);
      @define-color	pink  #ea76cb;
      @define-color	pink-rgb  rgb(234, 118, 203);
      @define-color	mauve  #8839ef;
      @define-color	mauve-rgb  rgb(136, 57, 239);
      @define-color	red  #d20f39;
      @define-color	red-rgb  rgb(210, 15, 57);
      @define-color	maroon  #e64553;
      @define-color	maroon-rgb  rgb(230, 69, 83);
      @define-color	peach  #fe640b;
      @define-color	peach-rgb  rgb(254, 100, 11);
      @define-color	yellow  #df8e1d;
      @define-color	yellow-rgb  rgb(223, 142, 29);
      @define-color	green  #40a02b;
      @define-color	green-rgb  rgb(64, 160, 43);
      @define-color	teal  #179299;
      @define-color	teal-rgb  rgb(23, 146, 153);
      @define-color	sky  #04a5e5;
      @define-color	sky-rgb  rgb(4, 165, 229);
      @define-color	sapphire  #209fb5;
      @define-color	sapphire-rgb  rgb(32, 159, 181);
      @define-color	blue  #1e66f5;
      @define-color	blue-rgb  rgb(30, 102, 245);
      @define-color	lavender  #7287fd;
      @define-color	lavender-rgb  rgb(114, 135, 253);
      @define-color	text  #4c4f69;
      @define-color	text-rgb  rgb(76, 79, 105);
      @define-color	subtext1  #5c5f77;
      @define-color	subtext1-rgb  rgb(92, 95, 119);
      @define-color	subtext0  #6c6f85;
      @define-color	subtext0-rgb  rgb(108, 111, 133);
      @define-color	overlay2  #7c7f93;
      @define-color	overlay2-rgb  rgb(124, 127, 147);
      @define-color	overlay1  #8c8fa1;
      @define-color	overlay1-rgb  rgb(140, 143, 161);
      @define-color	overlay0  #9ca0b0;
      @define-color	overlay0-rgb  rgb(156, 160, 176);
      @define-color	surface2  #acb0be;
      @define-color	surface2-rgb  rgb(172, 176, 190);
      @define-color	surface1  #bcc0cc;
      @define-color	surface1-rgb  rgb(188, 192, 204);
      @define-color	surface0  #ccd0da;
      @define-color	surface0-rgb  rgb(204, 208, 218);
      @define-color	base  #eff1f5;
      @define-color	base-rgb  rgb(239, 241, 245);
      @define-color	mantle  #e6e9ef;
      @define-color	mantle-rgb  rgb(230, 233, 239);
      @define-color	crust  #dce0e8;
      @define-color	crust-rgb  rgb(220, 224, 232);

      * {
        font-family: 'Inconsolata Nerd Font', monospace;
        font-size: 16px;
      }

      /* Window */
      window {
        margin: 0px;
        padding: 10px;
        border: 0.16em solid @lavender;
        border-radius: 10px;
        background-color: @base;
      }

      /* Inner Box */
      #inner-box {
        margin: 5px;
        padding: 10px;
        border: none;
        background-color: @base;
        animation: fadeIn 0.3s ease-in-out both;
      }

      /* Fade In */
      @keyframes fadeIn {
        0% {
           opacity: 0;
        }

        100% {
           opacity: 1;
        }
      }

      /* Outer Box */
      #outer-box {
        margin: 5px;
        padding: 10px;
        border: none;
        background-color: @base;
      }

      /* Scroll */
      #scroll {
        margin: 0px;
        padding: 10px;
        border: none;
        background-color: @base;
      }

      /* Input */
      #input {
        margin: 5px 20px;
        padding: 10px;
        border: none;
        border-radius: 10px;
        color: @text;
        background-color: @base;
        animation: fadeIn 0.3s ease-in-out both;
      }

      #input image {
          border: none;
          color: @red;
      }

      #input * {
        outline: 4px solid @red!important;
      }

      /* Text */
      #text {
        margin: 5px;
        border: none;
        color: @text;
        animation: fadeIn 0.3s ease-in-out both;
      }

      #entry {
        background-color: @base;
      }

      #entry arrow {
        border: 0.11em solid @base;
        color: @lavender;
      }

      /* Selected Entry */
      #entry:selected {
        border: 0.11em solid @lavender;
        border-radius: 8px;
      }

      #entry:selected #text {
        color: @mauve;
      }

      #entry:drop(active) {
        background-color: @lavender!important;
      }
    '';
  };
}

