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

      # Findy AI+ MCP サーバー設定（JSON形式、トークン含む）
      claude-mcp-findy-ai-plus = {
        path = "${config.xdg.configHome}/claude/.findy-mcp.json";
      };

      # Findy AI+ Prompt & Session Log 用 OpenTelemetry 設定（JSON形式、トークン含む）
      claude-otel-env = {
        path = "${config.xdg.configHome}/claude/.otel-env.json";
      };
    };
  };

  # XDG Base Directory configuration
  xdg.enable = true;
}
