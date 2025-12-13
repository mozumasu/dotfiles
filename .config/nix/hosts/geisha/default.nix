{ pkgs, ... }:
{
  networking.hostName = "geisha";
  system.primaryUser = "mozumasu";

  users.users.mozumasu = {
      name = "mozumasu";
      home = "/Users/mozumasu";
    };
}
