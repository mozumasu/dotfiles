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
    figlet
    glab
    google-cloud-sdk
    grafanactl
    gws
    nyancat
    nushell
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
    };

  # mocha-specific taps
  homebrew.taps = [
    "manaflow-ai/cmux"
    "timac/vpnstatus"
  ];

  # mocha-specific casks
  homebrew.casks = [
    "1password"
    "cmux"
    "docker-desktop"
    "jordanbaird-ice"
  ];
}
