{
  description = "Darwin configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      home-manager,
      darwin,
      ...
    }:
    {
      darwinConfigurations = {
        hostname = darwin.lib.darwinSystem {
          system = "x86_64-darwin";
          modules = [
            ./configuration.nix
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  users.jdoe = ./home.nix;
              };
            }
          ];
        };
      };
    };
}
