{ pkgs, config, ... }:
let
  modelName = "gpt-5.4";
in
{
  home.packages = with pkgs; [
    llm-agents.codex
  ];

  home.file.".codex/config.toml".text = ''
    personality = "pragmatic"
    model = "${modelName}"
    commit_attribution = "Codex (${modelName}) <noreply@openai.com>"
    suppress_unstable_features_warning = true

    [projects."${config.home.homeDirectory}/dotfiles"]
    trust_level = "trusted"

    [features]
    codex_git_commit = true
    codex_hooks = true
    undo = true
    voice_transcription = true
    realtime_conversation = true

    [hooks.session_start.log_session_start]
    command = "touch /tmp/codex-hooks-session_start"

    [hooks.stop.log_stop]
    command = "touch /tmp/codex-hooks-stop"
  '';
}
