{
  programs.git = {
    enable = true;
    userName = "Taha Ojari";
    userEmail = "paramoNNN@proton.me";
    extraConfig = {
      push = { autoSetupRemove = true; };
      pull = { rebase = true; };
      user = { signingkey = "FCF819681F9DD20E"; };
      commit = { gpgsign = true; };
    };
  };

  programs.git.delta = {
    enable = true;
    options = { syntax-theme = "gruvbox-light"; };
  };
}
