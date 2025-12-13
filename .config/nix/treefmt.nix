{ pkgs, ... }:
{
  projectRootFile = "flake.nix";

  programs = {
    # Nix
    nixfmt.enable = true;

    # Lua
    stylua.enable = true;

    # Shell
    shfmt.enable = true;

    # TOML
    taplo.enable = true;

    # YAML
    yamlfmt.enable = true;
  };

  settings.formatter = {
    # dotfiles 全体を対象にする
    nixfmt.includes = [
      "*.nix"
      ".config/nix/**/*.nix"
    ];

    stylua.includes = [
      ".config/nvim/**/*.lua"
    ];

    shfmt.includes = [
      ".config/zsh/**/*.zsh"
      "scripts/**/*.sh"
    ];
  };
}
