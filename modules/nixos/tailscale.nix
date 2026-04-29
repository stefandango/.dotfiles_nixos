{ config, lib, pkgs, ... }:

{
  # First-time setup: sudo tailscale up --login-server=<your-headscale-url>
  # tailscaled persists the login server after that — no need to bake it in here.
  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  networking.firewall = {
    checkReversePath = "loose";
    trustedInterfaces = [ "tailscale0" ];
  };
}
