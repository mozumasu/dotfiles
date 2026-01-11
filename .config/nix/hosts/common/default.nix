{ pkgs, ... }:
{
  # Common packages for all hosts
  environment.systemPackages = with pkgs; [
    # Basic tools
    git
    vim
    curl
    wget
    tree

    # Development tools
    gh

    # Utilities
    jq
  ];

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    interval = {
      Weekday = 0;
      Hour = 2;
      Minute = 0;
    };
    options = "--delete-older-than 30d";
  };
}
