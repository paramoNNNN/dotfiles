{
  config,
  lib,
  pkgs,
  private,
  ...
}:
let
  # This is a runtime path, never a Nix path literal or builtins.readFile input.
  affineTokenFile = "${config.xdg.configHome}/codex/affine-token";
  affineHeaders = pkgs.writeShellScript "codex-affine-headers" ''
    exec ${pkgs.python313}/bin/python3 ${./codex-affine-auth.py} ${lib.escapeShellArg affineTokenFile}
  '';
  grafanaTokenFile = "${config.xdg.configHome}/codex/grafana-token";
  grafanaMcp = pkgs.writeShellScript "codex-grafana-mcp" ''
    set -eu
    token_file=${lib.escapeShellArg grafanaTokenFile}
    if [ ! -r "$token_file" ] || [ ! -s "$token_file" ]; then
      echo "Grafana token unavailable. Save your service account token to $token_file with mode 600." >&2
      exit 1
    fi
    export GRAFANA_SERVICE_ACCOUNT_TOKEN="$( ${pkgs.coreutils}/bin/cat "$token_file" )"
    exec ${pkgs.mcp-grafana}/bin/mcp-grafana "$@"
  '';
  codexConfigHome =
    if config.home.preferXdgDirectories then
      "${config.xdg.configHome}/codex"
    else
      "${config.home.homeDirectory}/.codex";
  migrationPython = pkgs.python313.withPackages (ps: [ ps.tomlkit ]);
in
{
  # Mutable config merging retains old keys, so retire the previous env lookup.
  home.activation.codexAffineAuthMigration =
    lib.hm.dag.entryBetween [ "codexMutableSettings" ] [ "writeBoundary" ]
      ''
        run ${migrationPython}/bin/python3 - ${lib.escapeShellArg "${codexConfigHome}/config.toml"} <<'PY'
        import pathlib
        import sys
        import tomlkit

        path = pathlib.Path(sys.argv[1])
        if path.exists() and not path.is_symlink():
            document = tomlkit.parse(path.read_text())
            server = document.get("mcp_servers", {}).get("affine", {})
            if server.get("bearer_token_env_var") == "AFFINE_MCP_TOKEN":
                del server["bearer_token_env_var"]
                path.write_text(tomlkit.dumps(document))
        PY
      '';

  programs.codex = {
    enable = true;
    # Codex is installed by each host configuration.
    package = null;
    # Preserve local credentials and browser servers managed by the desktop app.
    mutableSettings = true;

    settings = {
      tui.vim_mode_default = true;
      approval_policy = "on-request";
      sandbox_mode = "workspace-write";
      model_reasoning_effort = "medium";

      mcp_servers = {
        sentry = {
          command = "${pkgs.nodejs}/bin/npx";
          args = [
            "-y"
            "@sentry/mcp-server@latest"
            "--skills=inspect"
          ];
          startup_timeout_sec = 120;
          env.SENTRY_HOST = private.codex.sentryHost;
          env_vars = [ "SENTRY_AUTH_TOKEN" ];
        };

        Gitlab.url = private.codex.gitlabUrl;

        grafana = {
          command = "${grafanaMcp}";
          args = [
            "-t"
            "stdio"
          ];
          env.GRAFANA_URL = private.codex.grafanaUrl;
          # Explicitly clear the old allowlist in Codex's mutable settings.
          env_vars = [ ];
        };

        affine = {
          url = private.codex.affineUrl;
          http_headers_helper = "${affineHeaders}";
        };

        plane = {
          command = "${pkgs.uv}/bin/uvx";
          args = [
            "--python"
            "${pkgs.python313}/bin/python3"
            "--no-python-downloads"
            "plane-mcp-server"
            "stdio"
          ];
          startup_timeout_sec = 120;
          env = {
            PLANE_BASE_URL = private.codex.planeBaseUrl;
            PLANE_WORKSPACE_SLUG = private.codex.planeWorkspaceSlug;
          };
          env_vars = [ "PLANE_API_KEY" ];
        };
      };
    };

    context = ''
      Use Nix to manage packages and configuration.
    '';
  };
}
