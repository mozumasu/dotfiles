{ pkgs, ... }:
{
  imports = [
    ./homebrew.nix
    ./homebrew-work.nix
    ./homebrew-personal.nix
  ];

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

    # Terminal and editor
    neovim
    wezterm
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
