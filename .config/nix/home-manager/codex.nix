{ pkgs, config, ... }:
{
  home.packages = with pkgs; [
    llm-agents.codex
  ];

  home.file.".codex/config.toml".text = ''
    personality = "pragmatic"
    model = "gpt-5.4"

    [projects."${config.home.homeDirectory}/dotfiles"]
    trust_level = "trusted"

    [features]
    undo = true
    voice_transcription = true
    suppress_unstable_features_warning = true
    realtime_conversation = true
  '';
}
