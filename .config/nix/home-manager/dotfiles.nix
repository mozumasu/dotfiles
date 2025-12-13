{ config, ... }:
let
  dotfilesPath = "${config.home.homeDirectory}/dotfiles";
  mkLink = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/${path}";
in
{
  # ~/.config/ 配下
  xdg.configFile = {
    "nvim".source = mkLink ".config/nvim";
    "wezterm".source = mkLink ".config/wezterm";
    "zsh".source = mkLink ".config/zsh";
    "aerospace".source = mkLink ".config/aerospace";
    "borders".source = mkLink ".config/borders";
    "ghostty".source = mkLink ".config/ghostty";
    "git".source = mkLink ".config/git";
    "karabiner".source = mkLink ".config/karabiner";
    "kitty".source = mkLink ".config/kitty";
    "lazygit".source = mkLink ".config/lazygit";
    "lazydocker".source = mkLink ".config/lazydocker";
    "starship.toml".source = mkLink ".config/starship.toml";
    "sheldon".source = mkLink ".config/sheldon";
    "yazi".source = mkLink ".config/yazi";
    "zeno".source = mkLink ".config/zeno";
    "gomi".source = mkLink ".config/gomi";
  };

  # ~/ 配下
  home.file = {
    ".gitconfig".source = mkLink ".gitconfig";
    ".tmux.conf".source = mkLink ".tmux.conf";
    ".nbrc".source = mkLink ".nbrc";
  };
}
