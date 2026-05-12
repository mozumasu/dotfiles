{ config, hostSpec, ... }:
let
  # Raycast today-calendar.sh 用 conf を host 別に切り替える
  todayCalendarConfKey =
    if hostSpec.isWork then "today-calendar-conf-work" else "today-calendar-conf-personal";
in
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

      # Raycast today-calendar.sh 用ローカル設定（host 別に切り替え）
      ${todayCalendarConfKey} = {
        path = "${config.xdg.configHome}/local/today-calendar.conf";
      };
    };
  };

  # XDG Base Directory configuration
  xdg.enable = true;
}
