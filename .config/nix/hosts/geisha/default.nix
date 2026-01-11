{ config, pkgs, ... }:
{
  # hostSpec configuration
  hostSpec = {
    hostName = "geisha";
    username = "mozumasu";
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

  # geisha-specific packages
  environment.systemPackages = with pkgs; [
    # Add geisha-specific tools here
  ];
}
