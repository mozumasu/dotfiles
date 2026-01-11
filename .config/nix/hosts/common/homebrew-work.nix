{ config, lib, ... }:
{
  homebrew = lib.mkIf config.hostSpec.isWork {
    # Work-only brews
    brews = [
      # Add work-specific brews here
    ];

    # Work-only casks
    casks = [
      # Communication
      # "chatwork"
      # "zoom"

      # AWS tools
      # "aws-vault-binary"
      # "session-manager-plugin"

      # API development
      # "postman"
    ];
  };
}
