{ pkgs, lib, ... }:
let
  tuigreet = "${pkgs.tuigreet}/bin/tuigreet";

  # tuigreet only accepts the 16 named ANSI colours (not hex). Those 16 slots
  # are themed to One Dark Pro via the vt.default_* kernel params in the host
  # config, so the names below resolve to the soft One Dark tones:
  #   gray=#abb2bf (fg), darkgray=#5c6370 (subtle), blue=#61afef, cyan=#56b6c2.
  # Keep it restrained — a faint border with blue/cyan accents, no clashing
  # bright primaries — so it reads as a themed login, not a mainframe terminal.
  theme = lib.concatStringsSep ";" [
    "container=black"   # box background -> #111111
    "border=darkgray"   # faint frame    -> #5c6370
    "title=blue"
    "greet=blue"
    "time=darkgray"     # de-emphasised clock
    "prompt=cyan"
    "input=gray"        # typed text in the One Dark fg
    "text=gray"
    "action=cyan"       # F-key action hints
    "button=blue"       # highlighted selection
  ];

  tuigreetCmd = lib.concatStringsSep " " [
    tuigreet
    "--time --time-format '%a %d %b  %H:%M'"
    "--greeting 'Welcome back, Stefan'"
    "--asterisks"                 # mask the password with * instead of hiding it
    "--user-menu"                 # pick the user from a list instead of typing it
    "--remember --remember-session"
    "--window-padding 4"          # breathing room from the screen edges
    "--container-padding 6"
    "--prompt-padding 1"
    "--theme '${theme}'"
    "--power-shutdown 'systemctl poweroff'"
    "--power-reboot 'systemctl reboot'"
    # Read the installed wayland session files and launch the selected one via
    # its own Exec line — this picks up the UWSM-managed Hyprland entry
    # ("uwsm start -e -D Hyprland hyprland.desktop"), which is how this system
    # is configured to start Hyprland (withUWSM = true).
    "--sessions /run/current-system/sw/share/wayland-sessions"
  ];
in
{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = tuigreetCmd;
        user = "greeter";
      };
    };
  };

  # this is a life saver.
  # literally no documentation about this anywhere.
  # might be good to write about this...
  # https://www.reddit.com/r/NixOS/comments/u0cdpi/tuigreet_with_xmonad_how/
  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal"; # Without this errors will spam on screen
    # Without these bootlogs will spam on screen
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };

  #environment.etc."greetd/environments".text = ''
  #  Hyprland
  #  fish
  #  bash
  #'';
}

