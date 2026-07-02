{ config, ... }:

{
  services.vert = {
    enable = true;
    hostName = "${config.networking.hostName}.${config.networking.domain}";
    nginx.enable = true;
  };
  networking = {
    hostName = "vert";
    domain = "local";
  };
  system.stateVersion = "26.11";
}
