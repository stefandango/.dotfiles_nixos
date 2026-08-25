{ lib, inputs, pkgs, ...}:

let
  # TEMP[dms-trial]: which desktop shell this machine runs.
  #
  #   "waybar" — waybar + rofi + swaync + hyprlock/hypridle (the long-standing stack)
  #   "dms"    — DankMaterialShell, one Quickshell process for all of the above
  #
  # The two are mutually exclusive by construction: only one set of modules is
  # imported, so they can never both claim org.kde.StatusNotifierWatcher (which
  # gates the CoreCtrl launch, and with it the GPU undervolt) or
  # org.freedesktop.Notifications.
  #
  # Flipping this value and rebuilding is a complete switch in either direction,
  # the same way `useLua` was a complete revert during the Hyprland Lua port.
  # TEMP-CHECK: recheck_after 2026-10-01
  desktopShell = "dms";
in
{
  # Make the selection visible to modules that straddle both stacks — chiefly
  # hyprland.nix, which owns the keybinds and the session autostart.
  _module.args.desktopShell = desktopShell;

  imports = [
    ./env.nix
    ./greetd.nix
    ./scripts.nix
    ./pyprland.nix
    ./hyprland.nix
    ./apps.nix
    ./dotnet.nix
    ./llama-cpp.nix
    ./tailscale.nix
    ./ntfy.nix
  ]
  ++ lib.optionals (desktopShell == "waybar") [
    ./waybar.nix
    ./rofi.nix
    ./swaync.nix
  ]
  ++ lib.optionals (desktopShell == "dms") [
    ./dms.nix
  ];
}
