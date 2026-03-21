{ config, ... }:
{
  # sops-nix configuration for user-level secrets
  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = ../secrets/user-secrets.yaml;

    secrets = {
      # czg configuration file
      czrc = {
        path = "${config.xdg.configHome}/.czrc";
      };

      # Claude Code 非公開マーケットプレイス設定（JSON形式）
      claude-private-marketplaces = {
        path = "${config.xdg.configHome}/claude/.private-marketplaces.json";
      };
    };
  };

  # XDG Base Directory configuration
  xdg.enable = true;
}
