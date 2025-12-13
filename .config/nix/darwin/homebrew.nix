{ ... }:
{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
    };
    taps = [ ];
    brews = [ ];
    casks = [ ];
  };
}
