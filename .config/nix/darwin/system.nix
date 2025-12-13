{ ... }:
{
  system.stateVersion = 5;
  programs.zsh.enable = true;
  security.pam.enableSudoTouchIdAuth = true;
}
