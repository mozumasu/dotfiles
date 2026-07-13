{
  config,
  ...
}:
{
  imports = [
    ./aliases.nix
    ./env.nix
    ./init.nix
  ];

  programs.zsh = {
    enable = true;

    # compinit は initContent 側で zsh-defer により遅延実行するため、
    # home-manager が生成する同期 compinit を無効化する
    enableCompletion = false;

    # ZDOTDIR の設定 (.config/zsh を使用)
    # 相対パスは非推奨のため、ホームディレクトリからの相対パスとして指定
    dotDir = "${config.xdg.configHome}/zsh";

    # ヒストリー設定
    history = {
      path = "${config.home.homeDirectory}/.config/zsh/.zsh_history";
      size = 100000;
      save = 100000;
      extended = true;
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      share = true;
      saveNoDups = true;
      expireDuplicatesFirst = true;
    };

    # セッション変数 (.zshrc で設定される変数)
    sessionVariables = {
      MANPAGER = "nvim +Man!";
      LESSHISTFILE = "\${XDG_STATE_HOME:-$HOME/.local/state}/less/history";
      LISTMAX = "50";
    };
  };

  # starship - キャッシュロジックを initContent で使用するため統合は無効
  programs.starship = {
    enable = true;
    enableZshIntegration = false;
  };

  # zoxide - キャッシュロジックを initContent で使用するため統合は無効
  programs.zoxide = {
    enable = true;
    enableZshIntegration = false;
  };

  # fzf - zeno を使っているので統合は無効
  programs.fzf = {
    enable = true;
    enableZshIntegration = false;
  };
}
