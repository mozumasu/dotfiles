{
  inputs = {
    systems.url = "github:nix-systems/default";
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    inputs@{
      self,
      systems,
      nixpkgs,
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.treefmt-nix.flakeModule
      ];
      systems = import systems;

      perSystem =
        {
          config,
          system,
          ...
        }:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfreePredicate =
              pkg:
              builtins.elem (nixpkgs.lib.getName pkg) [
                "terraform"
              ];
          };
          requiredTerraformVersion = builtins.replaceStrings [ "\n" ] [ "" ] (
            builtins.readFile ./.terraform-version
          );
          terraform = assert nixpkgs.lib.assertMsg
            (pkgs.terraform.version == requiredTerraformVersion)
            ".terraform-version requires terraform ${requiredTerraformVersion} but nixpkgs provides ${pkgs.terraform.version}. Run `nix flake update` or update .terraform-version.";
            pkgs.terraform;
        in
        {
          # CI用ツールセット
          packages.ci-tools = pkgs.buildEnv {
            name = "ci-tools";
            paths = [
              pkgs.tflint
              pkgs.trivy
              pkgs.gitleaks
              pkgs.rumdl
              config.treefmt.build.wrapper # treefmt
            ];
          };

          # ローカルでCIと同じチェックを実行するスクリプト
          packages.ci-local = pkgs.writeShellScriptBin "ci-local" ''
            set -euo pipefail

            ROOT_DIR=$(${pkgs.git}/bin/git rev-parse --show-toplevel)
            cd "$ROOT_DIR"

            echo "🔍 Running CI checks locally..."
            echo ""
            echo "📝 Checking format..."
            ${config.treefmt.build.wrapper}/bin/treefmt --fail-on-change
            echo "✅ Format check passed"
            echo ""
            echo "🔧 Running tflint..."
            ${pkgs.tflint}/bin/tflint --recursive --init --config="$ROOT_DIR/.tflint.hcl"
            echo "✅ tflint passed"
            echo ""
            echo "🛡️  Running trivy..."
            ${pkgs.trivy}/bin/trivy config --exit-code 1 .
            echo "✅ trivy passed"
            echo ""
            echo "🔐 Running gitleaks..."
            ${pkgs.gitleaks}/bin/gitleaks detect --no-git
            echo "✅ gitleaks passed"
            echo ""
            echo "📖 Running rumdl..."
            ${pkgs.rumdl}/bin/rumdl check .
            echo "✅ rumdl passed"
            echo ""
            echo "🎉 All CI checks passed!"
          '';

          devShells.default = pkgs.mkShell {
            buildInputs = [
              terraform
              pkgs.just
              # pkgs.lefthook
              pkgs.tflint
              pkgs.trivy
              pkgs.gitleaks
              pkgs.rumdl
            ];

            shellHook = ''
              # lefthook install
              echo "🚀 Terraform cli is available"
              echo "  - terraform version: $(terraform version | head -1)"
            '';
          };

          treefmt = {
            projectRootFile = "flake.nix";
            programs = {
              nixfmt.enable = true;
              actionlint.enable = true;
              terraform = {
                enable = true;
                package = terraform;
              };
            };
            settings.formatter.rumdl = {
              command = "${pkgs.rumdl}/bin/rumdl";
              options = [ "fmt" ];
              includes = [ "*.md" ];
            };
          };
        };
    };
}
