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
    exec ${pkgs.ntfy-sh}/bin/ntfy subscribe \
      --user "$NTFY_USER:$NTFY_PASSWORD" \
      "$NTFY_SERVER/$NTFY_TOPIC" \
      '${pkgs.libnotify}/bin/notify-send -a ntfy "$title" "$message"'
  '';
in
{
  home-manager.users.${vars.user} = {
    home.packages = with pkgs; [ ntfy-sh libnotify ];

    systemd.user.services.ntfy-subscribe = {
      Unit = {
        Description = "ntfy desktop notification subscriber";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${ntfyExec}";
        Restart = "on-failure";
        RestartSec = 10;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
