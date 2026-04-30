{
  config,
  lib,
  pkgs,
  ...
}:
{
  # hostSpec configuration
  hostSpec = {
    hostName = "F-00739-Mac";
    username = "ori.matsumoto";
    system = "aarch64-darwin";
    isWork = true;
    enableGUI = true;
  };

  # Hostname configuration
  networking.hostName = config.hostSpec.hostName;
  system.primaryUser = config.hostSpec.username;

  # User configuration
  users.users.${config.hostSpec.username} = {
    name = config.hostSpec.username;
    home = "/Users/${config.hostSpec.username}";
  };

  # mocha-specific packages
  environment.systemPackages = with pkgs; [
    _1password-cli
    btop
    ccplan
    discord
    figlet
    gcx
    glab
    google-cloud-sdk
    gws
    nyancat
    nushell
    open-policy-agent
    pup
    shishoctl
    thonny
    vde-layout
    vscode
  ];

  # mocha-specific brews
  homebrew.brews = [
    "agent-browser"
    "timac/vpnstatus/vpnutil"
  ];

  # agent-browser: Chromiumのダウンロード（初回のみ）
  # gcx: バンドルされた Agent Skills を ~/.agents にインストール（バージョン変更時のみ）
  home-manager.users.${config.hostSpec.username} =
    { lib, ... }:
    {
      home.activation.agentBrowserInstall = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        PLAYWRIGHT_CACHE="$HOME/Library/Caches/ms-playwright"
        AGENT_BROWSER="/opt/homebrew/bin/agent-browser"
        if [ -x "$AGENT_BROWSER" ] && [ ! -d "$PLAYWRIGHT_CACHE" ]; then
          export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
          "$AGENT_BROWSER" install
        fi
      '';

      home.activation.gcxSkillsInstall = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        GCX="${pkgs.gcx}/bin/gcx"
        MARKER="$HOME/.agents/.gcx-version"
        if [ -x "$GCX" ] && [ "$(cat "$MARKER" 2>/dev/null)" != "${pkgs.gcx.version}" ]; then
          "$GCX" skills install --all --force
          echo "${pkgs.gcx.version}" > "$MARKER"
        fi
      '';
    };

  # mocha-specific taps
  homebrew.taps = [
    "manaflow-ai/cmux"
    "timac/vpnstatus"
    "tw93/tap"
  ];

  # mocha-specific casks
  homebrew.casks = [
    "1password"
    "cmux"
    "docker-desktop"
    "jordanbaird-ice"
    "kaku"
  ];
}
