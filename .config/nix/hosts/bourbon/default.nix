{ pkgs, ... }:
{
  networking.hostName = "bourbon";
  system.primaryUser = "mozumasu";

  users.users.mozumasu = {
    name = "mozumasu";
    home = "/Users/mozumasu";
  };
}
