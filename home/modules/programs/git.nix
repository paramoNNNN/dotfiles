{
  hostname,
  userConfig,
  ...
}:
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = userConfig.fullName;
        email = userConfig.email;
        signingkey = userConfig.gitSigningKeys.${hostname};
      };
      push = {
        autoSetupRemote = true;
      };
      pull = {
        rebase = true;
      };
      commit = {
        gpgsign = true;
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
