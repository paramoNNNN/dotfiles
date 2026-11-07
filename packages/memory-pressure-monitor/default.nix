{ pkgs }:
pkgs.writeShellApplication {
  name = "memory-pressure-watch";
  runtimeInputs = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.libnotify ];
  text = ''
    exec ${pkgs.python3}/bin/python3 ${./monitor.py} "$@"
  '';
}
