{ ... }:
{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
    };

    taps = [
      "d12frosted/emacs-plus"
      "felixkratz/formulae"
      "mtgto/macskk"
      "nikitabobko/tap"
      "olets/tap"
      "sh0nk/tap"
      "shu-pf/tap"
      "timac/vpnstatus"
      "xwmx/taps"
    ];

    # macOS 固有、または nixpkgs にないツール
    brews = [
      # シェル関連
      "sheldon"
      "zsh-completions"

      # macOS 固有
      "felixkratz/formulae/borders"
      "switchaudio-osx"
      "nowplaying-cli"
      "terminal-notifier"
      "iproute2mac"
      "timac/vpnstatus/vpnutil"
      "xwmx/taps/nb"

      # バージョン管理ツール
      "tfenv"
      "mise"

      # 言語環境/ランタイム (mise で管理)
      "go"
      "rust"
      "lua"
      "luajit"
      "python@3.12"
      "python@3.9"
      "openjdk@11"
      "php"
      "php-cs-fixer"

      # データベース
      "postgresql@14"
      "postgresql@16"
      "mysql"
      "freetds"

      # ビルドツール (Java 依存)
      "gradle"
      "maven"

      # インフラ/DevOps
      "ansible"
      "ansible-lint"
      "docker"
      "colima"
      "lima"
      "qemu"
      "oha"

      # Python ツール
      "pipx"
      "cryptography"

      # メディア処理 (ライブラリ)
      "tesseract"
      "harfbuzz"
      "aom"
      "libheif"

      # その他ユーティリティ
      "gomi"
      "navi"
      "sshs"
      "sshpass"
      "subversion"
      "texinfo"
      "groff"
      "diffutils"

      # ライブラリ
      "glib"
      "libffi"
      "libgccjit"

      # 特殊 tap
      "d12frosted/emacs-plus/emacs-plus@30"
      "shu-pf/tap/dpl"
    ];

    casks = [
      "aerospace"
      "alacritty"
      "alt-tab"
      "android-file-transfer"
      "anki"
      "arc"
      "aws-vault-binary"
      "chatwork"
      "claude"
      "clip-studio-paint"
      "cursor"
      "dbeaver-community"
      "dockdoor"
      "figma"
      "font-hack-nerd-font"
      "font-hackgen"
      "font-hackgen-nerd"
      "font-sf-mono"
      "font-sf-pro"
      "font-udev-gothic-nf"
      "ghostty"
      "istat-menus"
      "iterm2"
      "jordanbaird-ice"
      "karabiner-elements"
      "keycastr"
      "kitty"
      "macskk"
      "multipass"
      "postman"
      "raycast"
      "session-manager-plugin"
      "sf-symbols"
      "shortcat"
      "spotify"
      "vagrant"
      "visual-studio-code"
      "timac/vpnstatus/vpnstatus"
      "warp"
      "wezterm@nightly"
      "zoom"
    ];
  };
}
