# robusta: Windows マシンの WSL (Ubuntu) 上で standalone home-manager として使う。
# nix-darwin 構成 (geisha/mocha/bourbon) とは独立したユーザー環境のみの管理。
# WezTerm は CorvusSKK クラッシュ修正入りの Windows 版 nightly を使うため
# ここには入れない (.config/windows/README.md 参照)。
{ pkgs, ... }:
{
  home.username = "mozumasu";
  home.homeDirectory = "/home/mozumasu";
  home.stateVersion = "24.11";
  home.enableNixpkgsReleaseCheck = false;

  programs.home-manager.enable = true;

  # 非 NixOS ディストリビューション (Ubuntu 等) 向けの統合
  # (セッション変数や XDG データディレクトリの設定)
  targets.genericLinux.enable = true;

  home.packages = with pkgs; [
    # エディタ/エージェント
    neovim
    herdr

    # シェルツール
    bat
    eza
    fd
    fzf
    jq
    ripgrep
    tree
    zoxide

    # Git 関連
    gh
    ghq
    delta
    lazygit

    # ターミナル環境
    starship
    tmux

    # Neovim の LSP/プラグインが要求するツールチェーン
    nodejs
    deno
    tree-sitter
  ];

  # direnv + nix-direnv
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
}
