{ lib, ... }:
{
  imports = [
    ./dotfiles.nix
  ];

  home.username = "mozumasu";
  home.homeDirectory = lib.mkForce "/Users/mozumasu";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;
}
