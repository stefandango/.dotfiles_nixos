{ lib, inputs, pkgs, ...}:
{
  imports = [
    ./env.nix
    ./regreet.nix
    ./scripts.nix
    ./waybar.nix
    ./pyprland.nix
    ./swaync.nix
    ./hyprland.nix
    ./rofi.nix
    ./apps.nix
    ./dotnet.nix
  ];
}
