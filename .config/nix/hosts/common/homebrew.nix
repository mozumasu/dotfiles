{ ... }:
{
  homebrew = {
    # Common brews for all hosts
    brews = [
      # Shell
      "sheldon"
      "zsh-completions"

      # macOS specific
      "felixkratz/formulae/borders"
      "switchaudio-osx"
      "nowplaying-cli"
      "terminal-notifier"
      "iproute2mac"
      "timac/vpnstatus/vpnutil"
      "xwmx/taps/nb"

      # Version managers
      "tfenv"
      "mise"

      # Languages/Runtimes (managed by mise)
      "go"
      "rust"
      "lua"
      "luajit"
      "python@3.12"
      "python@3.9"
      "openjdk@11"
      "php"
      "php-cs-fixer"

      # Databases
      "postgresql@14"
      "postgresql@16"
      "mysql"
      "freetds"

      # Build tools (Java dependent)
      "gradle"
      "maven"

      # Infrastructure/DevOps
      "ansible"
      "ansible-lint"
      "docker"
      "colima"
      "lima"
      "qemu"
      "oha"

      # Python tools
      "pipx"
      "cryptography"

      # Media processing (libraries)
      "tesseract"
      "harfbuzz"
      "aom"
      "libheif"

      # Other utilities
      "gomi"
      "navi"
      "sshs"
      "sshpass"
      "subversion"
      "texinfo"
      "groff"
      "diffutils"

      # Libraries
      "glib"
      "libffi"
      "libgccjit"

      # Special taps
      "d12frosted/emacs-plus/emacs-plus@30"
      "shu-pf/tap/dpl"
    ];

    # Common casks for all hosts
    casks = [
      # Window management
      "aerospace"
      "alt-tab"
      "dockdoor"
      "jordanbaird-ice"
      "shortcat"

      # Terminals
      "alacritty"
      "ghostty"
      "iterm2"
      "kitty"
      "warp"
      "wezterm@nightly"

      # Browsers
      "arc"

      # Development
      "cursor"
      "dbeaver-community"
      "postman"
      "visual-studio-code"

      # Productivity
      "anki"
      "claude"
      "figma"
      "raycast"

      # Communication
      "chatwork"
      "zoom"

      # System utilities
      "aws-vault-binary"
      "istat-menus"
      "karabiner-elements"
      "keycastr"
      "session-manager-plugin"
      "sf-symbols"
      "timac/vpnstatus/vpnstatus"

      # Input methods
      "macskk"

      # Fonts
      "font-hack-nerd-font"
      "font-hackgen"
      "font-hackgen-nerd"
      "font-sf-mono"
      "font-sf-pro"
      "font-udev-gothic-nf"

      # Virtualization
      "multipass"
      "vagrant"

      # Media
      "spotify"

      # Other
      "android-file-transfer"
      "clip-studio-paint"
    ];
  };
}
