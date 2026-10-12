{ pkgs }:
let
  python = pkgs.python3.withPackages (ps: [ ps.python-miio ]);
in
pkgs.writeShellApplication {
  name = "dms-xiaomi-bulb";
  text = ''
    exec ${python}/bin/python3 ${./control.py} "$@"
  '';
}
