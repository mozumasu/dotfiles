{ config, ... }:
{
  # sops-nix configuration for user-level secrets
  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = ../secrets/user-secrets.yaml;

    secrets = {
      # czg configuration file
      czrc = {
        path = "${config.xdg.configHome}/.czrc";
      };

      # Add more secrets here as needed
      # example-secret = {
      #   path = "${config.xdg.configHome}/secrets/example-secret";
      # };
    };
  };

  # XDG Base Directory configuration
  xdg.enable = true;
}
