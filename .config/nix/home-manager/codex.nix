{ pkgs, config, ... }:
{
  home.packages = with pkgs; [
    llm-agents.codex
  ];

  home.file.".codex/config.toml".text = ''
    personality = "pragmatic"
    model = "gpt-5.4"
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
    command = "sh -c 'printf \"%s session_start\\n\" \"$(date -Iseconds)\" >> /tmp/codex-hooks.log'"

    [hooks.stop.log_stop]
    command = "sh -c 'printf \"%s stop\\n\" \"$(date -Iseconds)\" >> /tmp/codex-hooks.log'"
  '';
}
