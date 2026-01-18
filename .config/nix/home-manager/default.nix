{ lib, pkgs, hostSpec, ... }:
{
  imports = [
    ./dotfiles.nix
    ./packages.nix
    ./zsh.nix
  ];

  home.username = hostSpec.username;
  home.homeDirectory = lib.mkForce "/Users/${hostSpec.username}";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  # direnv + nix-direnv
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # スクリーンショット保存先ディレクトリを作成
  home.activation.createScreenshotsDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ~/Pictures/Screenshots
  '';
}
