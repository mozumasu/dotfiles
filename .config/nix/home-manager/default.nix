{ lib, pkgs, ... }:
{
  imports = [
    ./dotfiles.nix
    ./packages.nix
  ];

  home.username = "mozumasu";
  home.homeDirectory = lib.mkForce "/Users/mozumasu";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  # スクリーンショット保存先ディレクトリを作成
  home.activation.createScreenshotsDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ~/Pictures/Screenshots
  '';
}
