{ pkgs, ... }: {
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting # Disable greeting;
      set fish_vi_key_bindings;
      set pure_show_system_time
      set pure_color_system_time white
    '';
    plugins = [
      {
        name = "pure";
        src = pkgs.fetchFromGitHub {
          owner = "pure-fish";
          repo = "pure";
          "rev" = "28447d2e7a4edf3c954003eda929cde31d3621d2";
          "hash" = "sha256-8zxqPU9N5XGbKc0b3bZYkQ3yH64qcbakMsHIpHZSne4=";
        };
      }
      {
        name = "fish-abbreviation-tips";
        src = pkgs.fetchFromGitHub {
          "owner" = "gazorby";
          "repo" = "fish-abbreviation-tips";
          "rev" = "8ed76a62bb044ba4ad8e3e6832640178880df485";
          "hash" = "sha256-F1t81VliD+v6WEWqj1c1ehFBXzqLyumx5vV46s/FZRU=";
        };
      }
      {
        name = "done";
        src = pkgs.fetchFromGitHub {
          "owner" = "franciscolourenco";
          "repo" = "done";
          "rev" = "eb32ade85c0f2c68cbfcff3036756bbf27a4f366";
          "hash" = "sha256-DMIRKRAVOn7YEnuAtz4hIxrU93ULxNoQhW6juxCoh4o=";
        };
      }
      {
        name = "autopair.fish";
        src = pkgs.fetchFromGitHub {
          "owner" = "jorgebucaran";
          "repo" = "autopair.fish";
          "rev" = "4d1752ff5b39819ab58d7337c69220342e9de0e2";
          "hash" = "sha256-qt3t1iKRRNuiLWiVoiAYOu+9E7jsyECyIqZJ/oRIT1A=";
        };
      }
      {
        name = "plugin-git";
        src = pkgs.fetchFromGitHub {
          "owner" = "jhillyerd";
          "repo" = "plugin-git";
          "rev" = "e4897db7abd43a74c902b5000c535b9da6ff766e";
          "hash" = "sha256-p7vvwisu3mvVOE1DcALbzuGJqWBcE1h71UjaopGdxE0=";
        };
      }
      {
        name = "z";
        src = pkgs.fetchFromGitHub {
          owner = "jethrokuan";
          repo = "z";
          rev = "85f863f20f24faf675827fb00f3a4e15c7838d76";
          sha256 = "sha256-+FUBM7CodtZrYKqU542fQD+ZDGrd2438trKM0tIESs0=";
        };
      }
    ];
    shellAliases = {
      ls = "eza --icons";
      go = "git open";
      nvim =
        "nvim --listen /tmp/nvim-server-(tmux display-message -p '#S-#{window_index}').pipe";
      cat = "bat --theme='Catppuccin Mocha'";
      nb = "sudo nixos-rebuild switch --flake ~/nixos#default";
      srv = "ssh taha@88.99.18.185 -p 1055";
      srv_cope = "ssh cope@88.99.18.185 -p 1055";
      srvv = "ssh taha@212.24.103.126 -p 1028";
      srv_2f = "ssh root@185.81.166.212";
      srv_2fst = "ssh root@62.77.158.4";
      srv_sr = "ssh root@138.199.148.33";
      srv_t = "ssh ubuntu@37.152.179.190 -p 1027";
      srv_router = "ssh root@192.168.1.1";
      srv_home = "ssh taha@192.168.1.192";
      ovpn_lt = "sudo /opt/homebrew/opt/openvpn/sbin/openvpn --config /Users/taha/ovpn/client.ovpn";
      ovpn_de = "sudo /opt/homebrew/opt/openvpn/sbin/openvpn --config /Users/taha/ovpn/taha-mac.ovpn";
    };
  };
}
