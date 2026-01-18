{
  config,
  lib,
  pkgs,
  ...
}:
let
  # dotfiles のパス
  dotfilesDir = "${config.home.homeDirectory}/dotfiles";
  zshConfigDir = "${dotfilesDir}/.config/zsh";
in
{
  programs.zsh = {
    enable = true;

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
      expireDuplicatesFirst = true;
    };

    # シェルエイリアス (alias.zsh の内容)
    shellAliases = {
      v = "nvim";
      "..." = "../../";
      "...." = "../../../";
      "....." = "../../../../";

      # rm
      gm = "gomi";

      # aws
      awsp = "set-aws-profile";
      awsvl = "aws-vault-login";
      ec2ls = "(echo -e \"InstanceId\\tName\\tPublicIpAddress\" && aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId, Tags[?Key==`Name`].Value | [0], PublicIpAddress]' --output text) | column -t";
      wsls = "get-workspaces-info";
      awsip = "get-aws-service-ip";
      iam = "check-iam-policy";
      ssmdv = "view-ssm-document";
      ssmdsync = "sync-ssm-document";
      awsconfig = "v ~/.aws/config";
      awscredentials = "v ~/.aws/credentials";

      # function alias
      sshf = "fzf-ssh";
      gi = "create-gitignore";

      # Claude
      claudeconfig = "v ~/Library/Application\\ Support/Claude/claude_desktop_config.json";

      # Mac - karabiner
      killkara = "sudo killall karabiner_grabber";

      # vpnutil
      vpns = "check-vpn-status";
      vpnc = "vpn-connect-with-fzf";
      vpnd = "vpn-disconnect-if-connected";

      # notification
      beep = "for i in {1..3}; do afplay /System/Library/Sounds/Submarine.aiff; done";

      # zmv
      mmv = "noglob zmv -W";
    };

    # セッション変数 (.zshrc で設定される変数)
    sessionVariables = {
      MANPAGER = "nvim +Man!";
      LESSHISTFILE = "\${XDG_STATE_HOME:-$HOME/.local/state}/less/history";
      LISTMAX = "50";
    };

    # .zshenv に追加する内容
    envExtra = ''
      # /etc/zprofile, /etc/zshrc, /etc/zlogin をスキップ
      # (/etc/zshenv は既に読み込み済み)
      setopt no_global_rcs

      # XDG
      export XDG_CONFIG_HOME=''${HOME}/.config
      export XDG_CACHE_HOME=''${HOME}/.cache
      export XDG_DATA_HOME=''${HOME}/.local/share
      export XDG_STATE_HOME=''${HOME}/.local/state

      # claude
      export CLAUDE_CONFIG_DIR=''${XDG_CONFIG_HOME}/claude

      # zsh
      export ZRCDIR=$ZDOTDIR/rc
      export LOCAL_ZSH_DIR="''${HOME}/.config/local/zsh"

      # path
      export PATH=''${HOME}/.local/bin:$PATH
      export PATH="/usr/local/sbin:$PATH"

      # lang
      export LANGUAGE="en_US.UTF-8"
      export LANG="''${LANGUAGE}"
      export LC_ALL="''${LANGUAGE}"
      export LC_CTYPE="''${LANGUAGE}"

      # editor
      export EDITOR=nvim
      export CVSEDITOR="''${EDITOR}"
      export SVN_EDITOR="''${EDITOR}"
      export GIT_EDITOR="''${EDITOR}"

      # bin/sbin for macOS
      export PATH="/usr/local/sbin:/usr/local/bin:$PATH"

      # Nix
      export PATH="/nix/var/nix/profiles/default/bin:$HOME/.nix-profile/bin:$PATH"

      # Go
      export GOPATH="$XDG_DATA_HOME/go"
      export GO111MODULE="on"
      export PATH=$XDG_DATA_HOME/go/bin:$PATH

      # Rust
      export PATH=$HOME/.cargo/bin:$PATH

      # Python
      export PATH=$PATH:$HOME/.rye/shims
      export PATH=$PATH:$HOME/Library/Python/2.7/bin

      # Java
      export JAVA_HOME=/opt/homebrew/Cellar/openjdk@11/11.0.26/libexec/openjdk.jdk/Contents/Home
      export PATH=$JAVA_HOME/bin:$PATH
      export CPPFLAGS="-I/opt/homebrew/opt/openjdk@11/include"

      # TiDB
      export PATH=$HOME/.tiup/bin:$PATH

      # pnpm
      export PNPM_HOME="$HOME/.local/share/pnpm"
      case ":$PATH:" in
        *":$PNPM_HOME:"*) ;;
        *) export PATH="$PNPM_HOME:$PATH" ;;
      esac

      # Homemade command
      export PATH=$XDG_CONFIG_HOME/local/bin:$PATH

      # mysql
      export PATH="/opt/homebrew/opt/mysql@8.0/bin:$PATH"

      # mise shims (for subprocesses like nvim)
      export PATH="$HOME/.local/share/mise/shims:$PATH"
    '';

    # .zshrc の内容 (initContent を使用)
    initContent = lib.mkMerge [
      # 最初に実行される部分 (mkBefore)
      (lib.mkBefore ''
        # ----------------------------------------------------
        # zcompile - Compile zsh files for faster loading
        # ----------------------------------------------------
        function ensure_zcompiled {
          local src=$1
          local zwc="$src.zwc"
          if [[ ! -r "$zwc" || "$src" -nt "$zwc" ]]; then
            zcompile "$src"
          fi
        }

        # Override source to auto-compile
        function source {
          ensure_zcompiled "$1"
          builtin source "$1"
        }

        # ----------------------------------------------------
        # homebrew (cached)
        # ----------------------------------------------------
        _brew_cache="''${XDG_CACHE_HOME:-$HOME/.cache}/zsh/brew-shellenv.zsh"
        if [[ ! -f "$_brew_cache" ]]; then
          mkdir -p "''${_brew_cache:h}"
          /opt/homebrew/bin/brew shellenv > "$_brew_cache"
        fi
        source "$_brew_cache"
        unset _brew_cache

        # Prioritize Japanese man pages
        export MANPATH="/usr/local/share/man/ja_JP.UTF-8:$(manpath)"
      '')

      # メイン部分
      ''
        # ----------------------------------------------------
        # Function
        # ----------------------------------------------------
        fpath=($ZRCDIR/functions $ZRCDIR/functions/*(/N) $fpath)
        autoload -Uz $ZRCDIR/functions/*(-.N:t) $ZRCDIR/functions/**/*(-.N:t)

        # ----------------------------------------------------
        # Keybind
        # ----------------------------------------------------
        source "$ZRCDIR/bindkey.zsh"

        # ----------------------------------------------------
        # sheldon
        # ----------------------------------------------------
        cache_dir=''${XDG_CACHE_HOME:-$HOME/.cache}
        sheldon_cache="$cache_dir/sheldon.zsh"
        sheldon_toml="$HOME/.config/sheldon/plugins.toml"
        if [[ ! -r "$sheldon_cache" || "$sheldon_toml" -nt "$sheldon_cache" ]]; then
          mkdir -p $cache_dir
          sheldon source > "$sheldon_cache"
          zcompile "$sheldon_cache"
        fi
        source "$sheldon_cache"
        unset cache_dir sheldon_cache sheldon_toml

        # ----------------------------------------------------
        # mise (zsh-defer で遅延実行)
        # ----------------------------------------------------
        if type mise &>/dev/null; then
          _mise_cache="''${XDG_CACHE_HOME:-$HOME/.cache}/mise.zsh"
          if [[ ! -r "$_mise_cache" || "$(command -v mise)" -nt "$_mise_cache" ]]; then
            mise activate zsh > "$_mise_cache"
            mise activate --shims >> "$_mise_cache"
            zcompile "$_mise_cache"
          fi
          zsh-defer source "$_mise_cache"
          unset _mise_cache
        fi

        # ----------------------------------------------------
        # Alias (additional)
        # ----------------------------------------------------
        # ls with eza
        if command -v eza >/dev/null 2>&1; then
          alias ls='eza'
        else
          alias ls='ls -F --color=auto'
        fi

        # run-help
        alias run-help >/dev/null 2>&1 && unalias run-help
        autoload -Uz run-help run-help-git run-help-openssl run-help-sudo

        # Hash
        hash -d xdata=$XDG_DATA_HOME
        hash -d nvim=$XDG_DATA_HOME/nvim
        hash -d nvimplugins=$XDG_DATA_HOME/nvim/lua

        # Homebrew wrapper
        function brew() {
          command brew "$@"
          if [[ "$1" == "install" || "$1" == "uninstall" ]]; then
            echo "Refreshing completions..."
            rm -f ''${ZDOTDIR:-~}/.zcompdump*
            compinit
          fi
        }

        # ----------------------------------------------------
        # Options
        # ----------------------------------------------------
        setopt correct
        setopt EXTENDED_HISTORY
        setopt hist_verify
        setopt hist_ignore_dups
        setopt hist_ignore_all_dups
        setopt hist_ignore_space
        setopt hist_no_store
        setopt hist_reduce_blanks
        setopt hist_save_no_dups
        setopt hist_expand
        setopt inc_append_history
        setopt auto_cd
        setopt auto_pushd
        setopt pushd_ignore_dups
        unsetopt bg_nice
        setopt list_packed
        setopt no_beep
        unsetopt list_types

        # tty
        if [[ -t 0 ]]; then
          stty -ixon
        fi

        # ----------------------------------------------------
        # other
        # ----------------------------------------------------
        umask 022
        autoload -U zmv

        # ----------------------------------------------------
        # completion (zsh-defer で遅延実行)
        # ----------------------------------------------------
        zstyle ':completion:*' matcher-list "" 'm:{[:lower:]}={[:upper:]}' '+m:{[:upper:]}={[:lower:]}'
        zstyle ':completion:*' format '%B%F{blue}%d%f%b'
        zstyle ':completion:*' group-name ""
        zstyle ':completion:*:default' menu select=2
        function _deferred_compinit() {
          autoload -Uz compinit
          _comp_dump="''${ZDOTDIR:-$HOME}/.zcompdump"
          _comp_zwc="$_comp_dump.zwc"
          # .zcompdump.zwc が最新なら source、なければ compinit して zcompile
          if [[ -r "$_comp_zwc" && "$_comp_zwc" -nt "$_comp_dump" ]]; then
            source "$_comp_dump"
          elif [[ -r "$_comp_dump" ]]; then
            source "$_comp_dump"
            zcompile "$_comp_dump"
          else
            compinit -d "$_comp_dump"
            zcompile "$_comp_dump"
          fi
          unset _comp_dump _comp_zwc
        }
        zsh-defer _deferred_compinit

        # ----------------------------------------------------
        # zsh local settings
        # ----------------------------------------------------
        if [[ -d "$LOCAL_ZSH_DIR" ]]; then
          for file in "$LOCAL_ZSH_DIR"/*.zsh; do
            [ -r "$file" ] && source "$file"
          done
        fi

        # ----------------------------------------------------
        # wezterm
        # ----------------------------------------------------
        zsh-defer -a source "$HOME/.config/zsh/rc/pluginconfig/wezterm.zsh"

        # ----------------------------------------------------
        # zeno.zsh
        # ----------------------------------------------------
        source "$HOME/.config/zsh/rc/pluginconfig/zeno.zsh"

        # ----------------------------------------------------
        # fzf
        # ----------------------------------------------------
        if [[ ! "$PATH" == */opt/homebrew/opt/fzf/bin* ]]; then
          PATH="''${PATH:+''${PATH}:}/opt/homebrew/opt/fzf/bin"
        fi
        zsh-defer source "$HOME/dotfiles/.config/zsh/rc/pluginconfig/fzf.key-bindings.zsh"

        # ----------------------------------------------------
        # starship
        # ----------------------------------------------------
        _starship_cache="''${XDG_CACHE_HOME:-$HOME/.cache}/starship.zsh"
        _starship_config="''${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"
        if [[ ! -r "$_starship_cache" || "$_starship_config" -nt "$_starship_cache" || "$(command -v starship)" -nt "$_starship_cache" ]]; then
          starship init zsh > "$_starship_cache"
          zcompile "$_starship_cache"
        fi
        source "$_starship_cache"
        unset _starship_cache _starship_config

        # ----------------------------------------------------
        # zoxide (Must be at the end of the file)
        # ----------------------------------------------------
        _zoxide_cache="''${XDG_CACHE_HOME:-$HOME/.cache}/zoxide.zsh"
        if [[ ! -r "$_zoxide_cache" || "$(command -v zoxide)" -nt "$_zoxide_cache" ]]; then
          zoxide init zsh > "$_zoxide_cache"
          zcompile "$_zoxide_cache"
        fi
        source "$_zoxide_cache"
        unset _zoxide_cache

        source ~/.safe-chain/scripts/init-posix.sh # Safe-chain Zsh initialization script
      ''
    ];
  };

  # starship - キャッシュロジックを initExtra で使用するため統合は無効
  programs.starship = {
    enable = true;
    enableZshIntegration = false;
  };

  # zoxide - キャッシュロジックを initExtra で使用するため統合は無効
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
