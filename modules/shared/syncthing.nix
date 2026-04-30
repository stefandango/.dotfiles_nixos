{ config, lib, pkgs, vars, ... }:

{
  services.syncthing = {
    enable = true;
    settings = {
      options = {
        globalAnnounceEnabled = false;
        relaysEnabled = false;
        urAccepted = -1;
      };
      devices.piserver = {
        id = "5LLOJQO-TQAQDAB-TGSQJCD-QIU4YQP-O67DWLH-N7S7TYB-YKEJA2S-ABLORQ7";
        addresses = [ "tcp://piserver:22000" ];
      };
      folders.vault = {
        path = "${config.home.homeDirectory}/Vault";
        devices = [ "piserver" ];
      };
    };
  };
}
