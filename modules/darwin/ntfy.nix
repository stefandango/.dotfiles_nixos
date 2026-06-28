{ config, lib, pkgs, vars, ... }:

let
  # Receive-only ntfy subscriber for macOS. There is no native Mac App Store
  # app or Homebrew cask for ntfy (the "Mac app" is just the iOS app on Apple
  # Silicon), so we mirror the NixOS setup: subscribe via the CLI and fire
  # native notifications through terminal-notifier.
  #
  # Credentials are sourced at runtime from an out-of-store file
  # (~/.config/ntfy/credentials, chmod 600, NOT in git), so no secret ever
  # lands in the Nix store. The single-quoted terminal-notifier command is
  # passed verbatim to `ntfy`, which runs it per message with $title/$message
  # set in that subshell's environment.
  ntfyExec = pkgs.writeShellScript "ntfy-subscribe" ''
    set -a
    . "$HOME/.config/ntfy/credentials"   # NTFY_USER, NTFY_PASSWORD, NTFY_SERVER, NTFY_TOPIC
    set +a
    exec ${pkgs.ntfy-sh}/bin/ntfy subscribe \
      --user "$NTFY_USER:$NTFY_PASSWORD" \
      "$NTFY_SERVER/$NTFY_TOPIC" \
      '${pkgs.terminal-notifier}/bin/terminal-notifier -title "$title" -message "$message"'
  '';
in
{
  home-manager.users.${vars.user} = {
    home.packages = with pkgs; [ ntfy-sh terminal-notifier ];

    launchd.agents.ntfy-subscribe = {
      enable = true;
      config = {
        ProgramArguments = [ "${ntfyExec}" ];
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/tmp/ntfy-subscribe.out.log";
        StandardErrorPath = "/tmp/ntfy-subscribe.err.log";
      };
    };
  };
}
