{ ... }:
{
  # Basic Homebrew settings (packages are defined in hosts/common/homebrew.nix)
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
    };

    taps = [
      "d12frosted/emacs-plus"
      "felixkratz/formulae"
      "mtgto/macskk"
      "nikitabobko/tap"
      "olets/tap"
      "sh0nk/tap"
      "shu-pf/tap"
      "timac/vpnstatus"
      "xwmx/taps"
    ];
  };
}
