{
  programs.git = {
    enable = true;
    userName = "Taha Ojari";
    userEmail = "taha.ojari@gmail.com";
    extraConfig = {
      push = { autoSetupRemove = true; };
      pull = { rebase = true; };
      user = { signingkey = "BE8CF963ABC092E0"; };
      commit = { gpgsign = true; };
    };
  };

  programs.git.delta = {
    enable = true;
    catppuccin = { enable = true; };
  };
}
