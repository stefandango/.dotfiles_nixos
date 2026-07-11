{ config, lib, pkgs, vars, ... }:

{
  services.syncthing = {
    enable = true;
    settings = {
      options = {
        globalAnnounceEnabled = false;
        relaysEnabled = false;
        urAccepted = -1;
        stunServers = [ ];        # empty the default grab-bag (drops stun.hitv.com etc.)
        stunKeepaliveStartS = 0;  # 0 = stop contacting STUN entirely
        natEnabled = false;       # no UPnP/NAT-PMP
        localAnnounceEnabled = false;  # mDNS off (LAN-only, cosmetic)
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
