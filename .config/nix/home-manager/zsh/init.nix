{ lib, ... }:
{
  # .zshrc の内容 (initContent を使用)
  programs.zsh.initContent = lib.mkMerge [
    # 最初に実行される部分 (mkBefore)
    (lib.mkBefore ''
      # ----------------------------------------------------
      # zcompile - Compile zsh files for faster loading
      # ----------------------------------------------------
      function ensure_zcompiled {
        local src=$1
        local zwc="$src.zwc"
        local dir="${"src:h"}"
        if [[ ! -w "$dir" ]]; then
          return
        fi
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
      # 日本語 man 設定を含まない旧形式キャッシュは作り直す
      if [[ ! -f "$_brew_cache" || "$(<$_brew_cache)" != *ja_JP.UTF-8* ]]; then
        mkdir -p "''${_brew_cache:h}"
        /opt/homebrew/bin/brew shellenv > "$_brew_cache"
        builtin source "$_brew_cache"
        # Prioritize Japanese man pages
        # manpath は brew の PATH を反映した状態で計算する必要がある
        print -r -- "export MANPATH=\"/usr/local/share/man/ja_JP.UTF-8:$(env -u MANPATH manpath)\"" >> "$_brew_cache"
      fi
      source "$_brew_cache"
      unset _brew_cache
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
      # zeno のロード時 deno cache を止める (zeno を読み込む sheldon より前で設定が必要)
      export ZENO_DISABLE_EXECUTE_CACHE_COMMAND=1

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

      # ----------------------------------------------------
      # Options
      # ----------------------------------------------------
      setopt correct
      # history: extended/share/ignore_dups 系は programs.zsh.history で設定済み
      setopt hist_verify
      setopt hist_no_store
      setopt hist_reduce_blanks
      setopt hist_expand
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
        # dump を source するだけでは compdef と complete-word 等の
        # 中核ウィジェットが定義されないため、必ず compinit を通す。
        # -C は compaudit と dump 再生成をスキップするので十分速い。
        if [[ -r "$_comp_dump" ]]; then
          compinit -C -d "$_comp_dump"
        else
          compinit -d "$_comp_dump"
          zcompile "$_comp_dump"
        fi
        unset _comp_dump
      }
      zsh-defer _deferred_compinit

      # ----------------------------------------------------
      # ntn (Notion CLI) completions
      # ----------------------------------------------------
      # compdef を使うため compinit の後に遅延実行する (zsh-defer は FIFO)
      if type ntn &>/dev/null; then
        _ntn_cache="''${XDG_CACHE_HOME:-$HOME/.cache}/ntn.zsh"
        if [[ ! -r "$_ntn_cache" || "$(command -v ntn)" -nt "$_ntn_cache" ]]; then
          ntn completions zsh > "$_ntn_cache"
          zcompile "$_ntn_cache"
        fi
        zsh-defer source "$_ntn_cache"
        unset _ntn_cache
      fi

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
      zsh-defer -a source "$ZRCDIR/pluginconfig/wezterm.zsh"

      # ----------------------------------------------------
      # zeno.zsh
      # ----------------------------------------------------
      source "$ZRCDIR/pluginconfig/zeno.zsh"

      # ----------------------------------------------------
      # fzf
      # ----------------------------------------------------
      if [[ ! "$PATH" == */opt/homebrew/opt/fzf/bin* ]]; then
        PATH="''${PATH:+''${PATH}:}/opt/homebrew/opt/fzf/bin"
      fi
      zsh-defer source "$ZRCDIR/pluginconfig/fzf.key-bindings.zsh"

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

      # Safe-chain (only if installed)
      [[ -f ~/.safe-chain/scripts/init-posix.sh ]] && source ~/.safe-chain/scripts/init-posix.sh
    ''
  ];
}
