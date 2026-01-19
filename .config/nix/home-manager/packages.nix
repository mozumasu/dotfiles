{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # シェルツール
    bat
    eza
    fd
    fzf
    hyperfine
    ripgrep
    zoxide
    tree
    wget
    jq
    tlrc # tldr

    # Git 関連
    git
    gh
    ghq
    lazygit
    delta # git-delta
    tig
    gibo
    git-secrets
    lefthook

    # エディタ/ターミナル
    neovim
    starship
    tmux

    # 開発ツール
    stylua
    typos
    actionlint
    tree-sitter
    deno
    rumdl # Markdown linter

    # ビルドツール
    cmake
    ninja

    # インフラ/DevOps
    awscli2
    k6
    vhs
    pre-commit

    # Python ツール
    uv

    # メディア処理
    ffmpeg
    imagemagick
    ghostscript

    # モニタリング/ユーティリティ
    bottom
    fastfetch
    glow
    presenterm # Terminal slideshow
    yazi
    lazydocker
    skanehira-ghost # Background process manager
    version-lsp # Package version checker LSP
    yaskkserv2 # SKK server

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
    inetutils # telnet
  ];
}
