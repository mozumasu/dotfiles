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

    # Git tools
    gh
    ghq
    gibo
    lazygit

    # Utilities
    jq
    tlrc
    starship

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
