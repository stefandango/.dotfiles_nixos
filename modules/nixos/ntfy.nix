{ config, lib, pkgs, vars, ... }:

let
  # Subscriber wrapper. Credentials are sourced at runtime from an
  # out-of-store file (~/.config/ntfy/credentials, chmod 600, NOT in git),
  # so no secret ever lands in the Nix store. The single-quoted notify-send
  # command is passed verbatim to `ntfy`, which runs it per message with
  # $title/$message set in that subshell's environment.
  ntfyExec = pkgs.writeShellScript "ntfy-subscribe" ''
    set -a
    . "$HOME/.config/ntfy/credentials"   # NTFY_USER, NTFY_PASSWORD, NTFY_SERVER, NTFY_TOPIC
    set +a
    # Comma-separated topics subscribe over a single connection. The primary
    # topic stays out-of-store via $NTFY_TOPIC; "alerts" is a fixed extra topic.
    exec ${pkgs.ntfy-sh}/bin/ntfy subscribe \
      --user "$NTFY_USER:$NTFY_PASSWORD" \
      "$NTFY_SERVER/$NTFY_TOPIC,alerts" \
      '${pkgs.libnotify}/bin/notify-send -a ntfy "$title" "$message"'
  '';
in
{
  home-manager.users.${vars.user} = {
    home.packages = with pkgs; [ ntfy-sh libnotify ];

    systemd.user.services.ntfy-subscribe = {
      # Bound to the user manager's default.target rather than
      # graphical-session.target: the plain (non-UWSM) Hyprland session never
      # activates graphical-session.target, so anything wired to it silently
      # fails to start after a reboot into that session. default.target is
      # reached on any login, so the subscriber comes up regardless of which
      # Hyprland entry the greeter launched. notify-send just waits for a
      # notification daemon (swaync) to register on the bus.
      Unit = {
        Description = "ntfy desktop notification subscriber";
        After = [ "default.target" ];
      };
      Service = {
        ExecStart = "${ntfyExec}";
        Restart = "on-failure";
        RestartSec = 10;
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
