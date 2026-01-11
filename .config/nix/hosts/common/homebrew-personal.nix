{ config, lib, ... }:
{
  homebrew = lib.mkIf (!config.hostSpec.isWork) {
    # Personal-only brews
    brews = [
      # Add personal-specific brews here
    ];

    # Personal-only casks
    casks = [
      # Media
      # "spotify"

      # Creative
      # "clip-studio-paint"

      # Gaming
      # "steam"
    ];
  };
}
