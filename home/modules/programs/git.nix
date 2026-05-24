{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Taha";
        email = "paramoNNN@proton.me";
      };
      extraConfig = {
        push = {
          autoSetupRemove = true;
        };
        pull = {
          rebase = true;
        };
        user = {
          signingkey = "FCF819681F9DD20E";
        };
        commit = {
          gpgsign = true;
        };
      };

      delta = {
        enable = true;
        options = {
          syntax-theme = "base16-stylix";
        };
      };
    };
  };
}
