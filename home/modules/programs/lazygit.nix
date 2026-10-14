{ config, pkgs, ... }:
let
  editFile = pkgs.writeShellScript "lazygit-edit" ''
    filename=$1
    line_number=''${2:-1}

    if [ -n "''${NVIM:-}" ]; then
      # Escape the path as a Vimscript string for the RPC expression.
      escaped_filename=$(printf '%s' "$filename" | ${pkgs.gnused}/bin/sed "s/\x27/\x27\x27/g")
      exec nvim --server "$NVIM" --remote-expr "v:lua.lazygitOpenFile('$escaped_filename', $line_number)"
    else
      exec nvim "+$line_number" -- "$filename"
    fi
  '';
in
{
  programs.lazygit = {
    enable = true;
    settings = {
      git = {
        pagers = [
          {
            colorArg = "always";
            pager = "delta --paging=never --${config.theme.variant}";
          }
        ];
        overrideGpg = true;
      };
      os = {
        edit = "${editFile} {{filename}}";
        editAtLine = "${editFile} {{filename}} {{line}}";
        open = "${editFile} {{filename}}";
        editInTerminal = true;
      };
      services = {
        "hamgit.ir" = "gitlab:hamgit.ir";
      };
    };
  };
}
