{ config, lib, pkgs, vars, ... }:

# wallgen: procedurally generated wallpapers at 5120x2160, one landscape per
# day relit for each phase (dawn/day/dusk/night). The phase follows the real
# sun at `location`, so in Copenhagen "day" is a few hours around noon in
# December and most of the evening in June. The image goes to DMS via
# `dms ipc call wallpaper set`, and DMS reruns matugen -- so the palette moves
# four times a day, never on a short shuffle (the reason cycling is off is in
# hyprland.nix, next to the carousel bind).
let
  # Copenhagen, degrees, east positive. Substituted into the script.
  location = "55.676 12.568";

  wallgen = pkgs.writers.writePython3Bin "wallgen"
    {
      libraries = with pkgs.python3Packages; [ numpy pillow ];
      flakeIgnore = [ "E501" "E731" "W503" "W504" ];
    }
    (builtins.replaceStrings [ "@location@" ] [ location ]
      (builtins.readFile ../scripts/wallgen.py));
in
{
  home-manager.users.${vars.user} = {
    home.packages = [ wallgen ];

    systemd.user.services.wallgen = {
      Unit.Description = "Render and apply the wallpaper for the current light";
      Service = {
        Type = "oneshot";
        # --auto exits at once unless the phase changed since the last image
        # it applied, so a wallpaper picked by hand in DMS survives until the
        # light changes. --wait-dms covers the login race with DMS starting.
        ExecStart = "${wallgen}/bin/wallgen --auto --wait-dms 90";
        # `dms` lives in the per-user profile, which the user manager's PATH
        # does not include.
        Environment = "PATH=/etc/profiles/per-user/${vars.user}/bin:/run/current-system/sw/bin";
        Nice = 10;
      };
    };

    systemd.user.timers.wallgen = {
      Unit.Description = "Check whether the light outside has changed phase";
      Timer = {
        # Phase boundaries move with the season, so poll rather than schedule;
        # an unchanged phase costs one Python start-up.
        OnCalendar = "*:0/10";
        OnStartupSec = "20s";
      };
      # default.target, not graphical-session.target: the plain Hyprland
      # session never reaches the latter (see modules/nixos/ntfy.nix).
      Install.WantedBy = [ "default.target" ];
    };
  };
}
