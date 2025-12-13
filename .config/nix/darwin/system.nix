{ ... }:
{
  system.stateVersion = 5;
  programs.zsh.enable = true;
  security.pam.services.sudo_local.touchIdAuth = true;
}
