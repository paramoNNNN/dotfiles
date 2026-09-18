{
  inputs,
  pkgs,
  ...
}:
let
  aerospace-swipe = pkgs.stdenv.mkDerivation {
    pname = "aerospace-swipe";
    version = "unstable";
    src = inputs.aerospace-swipe;

    postPatch = ''
      substituteInPlace makefile \
        --replace-fail "codesign --entitlements" "/usr/bin/codesign --entitlements"
    '';

    buildPhase = ''
      runHook preBuild
      make bundle
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/Applications"
      cp -R AerospaceSwipe.app "$out/Applications/"
      runHook postInstall
    '';
  };
in
{
  # Homebrew owns the app; Home Manager owns its canonical configuration.
  # The existing ~/.aerospace.toml symlink is backed up on first activation.
  home.file.".aerospace.toml".source = ./aerospace.toml;

  xdg.configFile."aerospace-swipe/config.json".text = builtins.toJSON {
    fingers = 3;
    haptic = false;
    natural_swipe = false;
    skip_empty = true;
    wrap_around = false;
  };

  launchd.agents.aerospace-swipe = {
    enable = true;
    config = {
      ProgramArguments = [
        "${aerospace-swipe}/Applications/AerospaceSwipe.app/Contents/MacOS/AerospaceSwipe"
      ];
      KeepAlive = true;
      RunAtLoad = true;
      LimitLoadToSessionType = "Aqua";
      ProcessType = "Interactive";
      StandardOutPath = "/tmp/aerospace-swipe.out";
      StandardErrorPath = "/tmp/aerospace-swipe.err";
    };
  };
}
