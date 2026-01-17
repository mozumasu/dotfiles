{ ... }:
{
  homebrew = {
    # Common brews for all hosts (work-essential tools)
    brews = [
      # Shell
      "sheldon" # for zeno.zsh
      "zsh-completions"

      # macOS specific
      "felixkratz/formulae/borders"
      "xwmx/taps/nb"

      # Container runtime
      "docker"
      "colima"
    ];

    # Common casks for all hosts (work-essential apps)
    casks = [
      # Window management
      "aerospace"
      "alt-tab"
      "homerow"

      # Terminals
      "ghostty"
      "wezterm@nightly"

      # Browsers
      "arc"

      # System utilities
      "aws-vault-binary"
      "karabiner-elements"

      # Input methods
      "macskk"
    ];
  };
}
