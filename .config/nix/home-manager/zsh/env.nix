{
  # .zshenv に追加する内容
  programs.zsh.envExtra = ''
    # /etc/zprofile, /etc/zshrc, /etc/zlogin をスキップ
    # (/etc/zshenv は既に読み込み済み)
    setopt no_global_rcs

    # XDG
    export XDG_CONFIG_HOME=''${HOME}/.config
    export XDG_CACHE_HOME=''${HOME}/.cache
    export XDG_DATA_HOME=''${HOME}/.local/share
    export XDG_STATE_HOME=''${HOME}/.local/state

    # claude
    # home-manager activation で ~/.config/claude/ にシンボリンク + settings.json を配置済み
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
}
