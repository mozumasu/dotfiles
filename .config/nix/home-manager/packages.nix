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
    gitSVN
    gh
    ghq
    delta # git-delta
    tig
    gibo
    git-secrets
    lefthook
    czg
    mergiraf # syntax-aware git merge driver

    # エディタ/ターミナル
    neovim
    starship
    tmux
    herdr

    # 開発ツール
    lua # wezterm の preview スクリプト等で使用
    stylua
    typos
    actionlint
    tree-sitter
    deno
    rumdl # Markdown linter
    nodejs # for Mason LSP servers
    playwright-cli
    go # for gopls etc.
    rustup # for building sniprun.nvim, etc.
    portless # dev サーバーのポート自動割り当て

    # ビルドツール
    cmake
    ninja

    # インフラ/DevOps
    awscli2
    k6
    vhs
    tfupdate
    # pre-commit # 一時的に無効化（swiftビルドエラー回避）

    # Python ツール
    uv

    # メディア処理
    ffmpeg
    imagemagick
    ghostscript
    pngpaste # img-clip.nvim で画像をクリップボードから貼り付け

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
    safe-chain # Block malicious packages
    ccsession # claude --resume の fzf フロントエンド

    # ネタ系
    cowsay
    cmatrix
    nyancat
    asciiquarium
    asciinema

    # Google Workspace CLI
    gogcli

    # Slack
    slack-cli # Official Slack platform CLI

    # ノート
    nb
    ntn # Notion CLI

    # その他
    translate-shell
    nkf
    rename
    inetutils # telnet
  ];
}
