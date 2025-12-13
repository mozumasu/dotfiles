{ config, ... }:
let
  dotfilesPath = "${config.home.homeDirectory}/dotfiles";
in
{
  # 後で追加
  # xdg.configFile."nvim".source = "${dotfilesPath}/.config/nvim";
}
