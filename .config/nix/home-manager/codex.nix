{ config, ... }:
{
  home.file.".codex/config.toml".text = ''
    personality = "pragmatic"
    model = "gpt-5.4"

    [projects."${config.home.homeDirectory}/dotfiles"]
    trust_level = "trusted"

    [features]
    undo = true
  '';
}
