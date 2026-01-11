{ lib, ... }:
{
  options.hostSpec = {
    hostName = lib.mkOption {
      type = lib.types.str;
      description = "Hostname";
    };

    username = lib.mkOption {
      type = lib.types.str;
      default = "mozumasu";
      description = "Username";
    };

    system = lib.mkOption {
      type = lib.types.str;
      default = "aarch64-darwin";
      description = "System architecture";
    };

    isDarwin = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether this is a Darwin system";
    };

    isMinimal = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to use minimal configuration";
    };

    isWork = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether this is a work machine";
    };

    enableGUI = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable GUI applications";
    };
  };
}
