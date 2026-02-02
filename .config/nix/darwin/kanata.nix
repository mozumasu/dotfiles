{ config, ... }:
{
  services.kanata = {
    enable = true;
    keyboards = {
      macbook = {
        configFile = "/Users/${config.hostSpec.username}/dotfiles/.config/kanata/macbook.kbd";
        port = 5829;
      };
      external = {
        configFile = "/Users/${config.hostSpec.username}/dotfiles/.config/kanata/external.kbd";
        port = 5830;
      };
    };
  };
}
