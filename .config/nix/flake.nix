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
    version-lsp = {
      url = "github:skanehira/version-lsp";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    kawarimidoll-nur = {
      url = "github:kawarimidoll/nur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
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
      version-lsp,
      kawarimidoll-nur,
      ...
    }:
    let
      system = "aarch64-darwin";

      # Custom overlay for local packages
      localOverlay = final: prev: {
        skanehira-ghost = final.callPackage ./packages/ghost.nix { };
        version-lsp = version-lsp.packages.${system}.default;
        plamo-translate = kawarimidoll-nur.packages.${system}.plamo-translate;
      };

      pkgs = import nixpkgs {
        inherit system;
        overlays = [ localOverlay ];
      };
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

      # Common modules shared by all hosts
      commonModules = [
        # Import hostSpec module
        ./modules/hostSpec.nix
        # Common settings for all hosts
        ./hosts/common
        # Darwin-specific settings
        ./darwin
        # Apply custom overlay to nixpkgs
        {
          nixpkgs.overlays = [ localOverlay ];
        }
        home-manager.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";
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
          modules = [ ./hosts/geisha ] ++ commonModules;
        };

        bourbon = darwin.lib.darwinSystem {
          inherit system;
          modules = [ ./hosts/bourbon ] ++ commonModules;
        };
      };
    };
}
