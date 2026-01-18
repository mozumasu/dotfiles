{ config, lib, ... }:
{
  homebrew = lib.mkIf (!config.hostSpec.isWork) {
    # Personal-only brews
    brews = [
      # macOS specific
      "switchaudio-osx"
      "nowplaying-cli"
      "terminal-notifier"
      "iproute2mac"
      "timac/vpnstatus/vpnutil"

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

    # Personal-only casks
    casks = [
      # Window management
      "dockdoor"
      "jordanbaird-ice"
      "shortcat"

      # Terminals
      "alacritty"
      "iterm2"
      "kitty"
      "warp"

      # Development
      "cursor"
      "dbeaver-community"
      "postman"
      "visual-studio-code"

      # Productivity (raycast is in common homebrew.nix)
      "anki"
      "claude"
      "figma"

      # Communication
      "chatwork"
      "zoom"

      # System utilities
      "istat-menus"
      "keycastr"
      "session-manager-plugin"
      "sf-symbols"
      "timac/vpnstatus/vpnstatus"

      # Fonts (hackgen fonts are in common homebrew.nix)
      "font-hack-nerd-font"
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
