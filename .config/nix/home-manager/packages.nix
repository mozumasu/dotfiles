{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # シェルツール
    bat
    eza
    fd
    fzf
    ripgrep
    zoxide
    tree
    wget
    jq

    # Git 関連
    gh
    ghq
    lazygit
    delta # git-delta
    tig

    # エディタ/ターミナル
    neovim
    starship
    tmux

    # 開発ツール
    stylua
    typos

    # モニタリング/ユーティリティ
    bottom
    fastfetch
    glow
    yazi

    # ネタ系
    cowsay
    cmatrix
    nyancat
    asciiquarium
    asciinema

    # その他
    translate-shell
    nkf
    rename
  ];
}
