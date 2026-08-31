{ inputs, pkgs, ...}:

{
  imports = [
    ./env.nix
    ./greetd.nix
    ./scripts.nix
    ./pyprland.nix
    ./hyprland.nix
    ./dms.nix
    ./apps.nix
    ./dotnet.nix
    ./llama-cpp.nix
    ./tailscale.nix
    ./ntfy.nix
  ];
}
