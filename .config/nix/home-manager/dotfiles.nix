{ config, pkgs, ... }:
let
  dotfilesPath = "${config.home.homeDirectory}/dotfiles";
  mkLink = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/${path}";
in
{
  # ~/.config/ 配下
  xdg.configFile = {
    "nvim".source = mkLink ".config/nvim";
    "wezterm".source = mkLink ".config/wezterm";
    # zsh は programs.zsh で管理するため、サブディレクトリのみリンク
    "zsh/rc".source = mkLink ".config/zsh/rc";
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
    "mise".source = mkLink ".config/mise";
    "claude".source = mkLink ".config/claude";
  };

  # ~/ 配下
  home.file = {
    ".gitconfig".source = mkLink ".gitconfig";
    ".tmux.conf".source = mkLink ".tmux.conf";
    ".nbrc".source = mkLink ".nbrc";

    # Claude Code skills directory
    # Claude Codeはスキルを ~/.claude/skills/ から読み込むため、
    # .config/claude/skills をここにシンボリックリンク
    ".claude/skills".source = mkLink ".config/claude/skills";
  };

  # macSKK dictionaries - copy instead of symlink due to sandbox restrictions
  home.activation.macSKKDictionaries = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    DICT_DIR="$HOME/Library/Containers/net.mtgto.inputmethod.macSKK/Data/Documents/Dictionaries"
    mkdir -p "$DICT_DIR"
    cp -f "${pkgs.skkDictionaries.l}/share/skk/SKK-JISYO.L" "$DICT_DIR/"
    cp -f "${pkgs.skkDictionaries.jinmei}/share/skk/SKK-JISYO.jinmei" "$DICT_DIR/"
    cp -f "${pkgs.skkDictionaries.geo}/share/skk/SKK-JISYO.geo" "$DICT_DIR/"
    cp -f "${pkgs.skkDictionaries.emoji}/share/skk/SKK-JISYO.emoji" "$DICT_DIR/"
    chmod 644 "$DICT_DIR"/SKK-JISYO.*
  '';

  # nb repository - clone if not exists
  home.activation.cloneNbRepository = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    NB_DIR="$HOME/src/github.com/mozumasu/nb"
    mkdir -p "$NB_DIR"

    if [ ! -d "$NB_DIR/home/.git" ]; then
      rm -rf "$NB_DIR/home"
      ${pkgs.git}/bin/git clone https://github.com/mozumasu/nb-home.git "$NB_DIR/home"
    fi
  '';
}
