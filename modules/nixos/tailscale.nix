{ config, lib, pkgs, vars, ... }:

{
  # First-time setup: sudo tailscale up --login-server=<your-headscale-url>
  # tailscaled persists the login server after that — no need to bake it in here.
  services.tailscale = {
    enable = true;
    openFirewall = true;

    # Without an operator, every pref-changing call fails with
    #   Access denied: checkprefs access denied
    # even though the socket is mode 0666 — tailscaled does its own check and
    # only trusts root or the configured operator. Reads (`tailscale status`)
    # are unaffected, which is why the waybar indicator and the DMS control
    # centre toggle looked fine while connect/disconnect, exit nodes, routes
    # and DNS all silently refused.
    #
    # This is applied by the tailscaled-set oneshot, which nixpkgs defines
    # whenever extraSetFlags is non-empty — it does not need authKeyFile the
    # way extraUpFlags does.
    extraSetFlags = [ "--operator=${vars.user}" ];
  };

  networking.firewall = {
    checkReversePath = "loose";
    trustedInterfaces = [ "tailscale0" ];
  };
}
