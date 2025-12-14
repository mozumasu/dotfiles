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
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      darwin,
      treefmt-nix,
      nix-homebrew,
      homebrew-core,
      homebrew-cask,
      ...
    }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
      treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;

      # Flake directory path
      flakeDir = "$HOME/dotfiles/.config/nix";

      # Helper to create app
      mkApp = name: script: {
        type = "app";
        program = "${
          pkgs.writeShellApplication {
            inherit name;
            text = script;
          }
        }/bin/${name}";
      };
    in
    {
      formatter.${system} = treefmtEval.config.build.wrapper;

      checks.${system}.formatting = treefmtEval.config.build.check ./.;

      apps.${system} = {
        # nix run .#switch
        switch = mkApp "darwin-switch" ''
          sudo darwin-rebuild switch --flake "${flakeDir}#geisha"
        '';

        # nix run .#build
        build = mkApp "darwin-build" ''
          darwin-rebuild build --flake "${flakeDir}#geisha"
        '';

        # nix run .#check
        check = mkApp "darwin-check" ''
          darwin-rebuild check --flake "${flakeDir}#geisha"
        '';

        # nix run .#update
        update = mkApp "darwin-update" ''
          echo "Updating flake..."
          nix flake update --flake "${flakeDir}"
          echo "Rebuilding nix-darwin (includes home-manager)..."
          sudo darwin-rebuild switch --flake "${flakeDir}#geisha"
          echo "Update complete!"
        '';
      };

      darwinConfigurations = {
        geisha = darwin.lib.darwinSystem {
          inherit system;
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
            nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew = {
                enable = true;
                enableRosetta = true;
                user = "mozumasu";
                autoMigrate = true;
                taps = {
                  "homebrew/homebrew-core" = homebrew-core;
                  "homebrew/homebrew-cask" = homebrew-cask;
                };
                mutableTaps = true;
              };
            }
          ];
        };
      };
    };
}
