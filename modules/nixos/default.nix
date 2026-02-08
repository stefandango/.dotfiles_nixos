{ lib, inputs, pkgs, ...}:
{
  imports = [
    ./env.nix
    ./greetd.nix
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
