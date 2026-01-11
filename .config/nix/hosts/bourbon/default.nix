{ config, pkgs, ... }:
{
  # hostSpec configuration
  hostSpec = {
    hostName = "bourbon";
    username = "mozumasu";
    system = "aarch64-darwin";
    isWork = false;
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

  # bourbon-specific packages
  environment.systemPackages = with pkgs; [
    # Add bourbon-specific tools here
  ];
}
