{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:

buildNpmPackage rec {
  pname = "avante-codex-acp";
  version = "1.11.0";

  src = fetchFromGitHub {
    owner = "agentclientprotocol";
    repo = "codex-acp";
    rev = "v${version}";
    hash = "sha256-u3uYZnMVJHGF9IWlXdIAdHWPiGC3ENFIEAaU4Nv0l7M=";
  };

  npmDepsHash = "sha256-MpBjRpOrOE7mGAAZEe1jwxR0XLf7IXsdWhtkAhuREaM=";

  meta = {
    description = "ACP adapter for the Codex CLI";
    homepage = "https://github.com/agentclientprotocol/codex-acp";
    license = lib.licenses.asl20;
    mainProgram = "codex-acp";
  };
}
