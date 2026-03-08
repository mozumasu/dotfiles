{ config, pkgs, ... }:
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
    ccplan
    google-cloud-sdk
    nushell
    pup
  ];

  # gws is temporarily installed via Homebrew until nixpkgs-unstable picks up nixpkgs PR #496806
  homebrew.brews = [
    "gws"
  ];

  # mocha-specific taps
  homebrew.taps = [
    "manaflow-ai/cmux"
  ];

  # mocha-specific casks
  homebrew.casks = [
    "cmux"
    "docker-desktop"
    "jordanbaird-ice"
  ];
}
