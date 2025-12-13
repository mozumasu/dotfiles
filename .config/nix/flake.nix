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
      nixpkgs,
      home-manager,
      darwin,
      ...
    }:
    {
      darwinConfigurations = {
        geisha = darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            ./hosts/geisha
            ./darwin
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  users.mozumasu = import ./home-manager;
              };
            }
          ];
        };
      };
    };
}
