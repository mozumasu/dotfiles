{
  config,
  lib,
  hostSpec,
  ...
}:
let
  # Raycast today-calendar.sh 用 conf を host 別に切り替える
  todayCalendarConfKey =
    if hostSpec.isWork then "today-calendar-conf-work" else "today-calendar-conf-personal";

  # 業務用 L2TP VPN の構成プロファイル。復号後は `open` して System Settings > 一般 > デバイス管理 で手動インストールする
  # (macOS 11+ は `profiles install` でユーザープロファイルを入れられない)
  vpnMobileconfig = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>PayloadContent</key>
      <array>
        <dict>
          <key>PayloadType</key>
          <string>com.apple.vpn.managed</string>
          <key>PayloadVersion</key>
          <integer>1</integer>
          <key>PayloadIdentifier</key>
          <string>com.mozumasu.vpn.l2tp</string>
          <key>PayloadUUID</key>
          <string>13A8F3EA-A9D3-4135-8216-EBC3789F2672</string>
          <key>PayloadDisplayName</key>
          <string>vpn-i</string>
          <key>UserDefinedName</key>
          <string>vpn-i</string>
          <key>VPNType</key>
          <string>L2TP</string>
          <key>PPP</key>
          <dict>
            <key>AuthName</key>
            <string>o_matsumoto@iridge0</string>
            <key>AuthPassword</key>
            <string>${config.sops.placeholder.vpn-l2tp-password}</string>
            <key>CommRemoteAddress</key>
            <string>gw116.flexrmt.kddi.ne.jp</string>
          </dict>
          <key>IPSec</key>
          <dict>
            <key>AuthenticationMethod</key>
            <string>SharedSecret</string>
            <key>LocalIdentifierType</key>
            <string>KeyID</string>
            <key>SharedSecret</key>
            <data>${config.sops.placeholder.vpn-l2tp-shared-secret-base64}</data>
          </dict>
          <key>IPv4</key>
          <dict>
            <key>OverridePrimary</key>
            <integer>1</integer>
          </dict>
        </dict>
      </array>
      <key>PayloadType</key>
      <string>Configuration</string>
      <key>PayloadVersion</key>
      <integer>1</integer>
      <key>PayloadIdentifier</key>
      <string>com.mozumasu.profile.vpn</string>
      <key>PayloadUUID</key>
      <string>A3380C66-97F7-4EC3-B8F7-A3AA30494CE8</string>
      <key>PayloadDisplayName</key>
      <string>vpn-i (L2TP)</string>
    </dict>
    </plist>
  '';
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

      # GitHub Packages (npm.pkg.github.com) 用 PAT (read:packages)
      github-packages-token = { };
    }
    // lib.optionalAttrs hostSpec.isWork {
      vpn-l2tp-password = { };
      # plist の SharedSecret は data 型なので base64 済みの値を格納する (`printf '%s' SECRET | base64`)
      vpn-l2tp-shared-secret-base64 = { };
    };

    templates = {
      # npm の private registry 設定。user config は globalconfig より優先される
      ".npmrc" = {
        content = ''
          registry=https://npm.flatt.tech/
          //npm.pkg.github.com/:_authToken=${config.sops.placeholder.github-packages-token}
        '';
        path = "${config.home.homeDirectory}/.npmrc";
      };
    }
    // lib.optionalAttrs hostSpec.isWork {
      "vpn.mobileconfig" = {
        content = vpnMobileconfig;
        path = "${config.xdg.configHome}/local/vpn.mobileconfig";
      };
    };
  };

  # XDG Base Directory configuration
  xdg.enable = true;
}
