{ lib, inputs, pkgs, ...}:
{
  # You can import other home-manager modules here
  imports = [
    #./nvim.nix
      ../env.nix
      ../greetd.nix
      ../scripts.nix
      ../waybar.nix
      ../pyprland.nix
      ../swaync.nix
      ../hyprland.nix
      ../rofi.nix
      ../../theme/theming.nix
      #../git.nix
      ../kitty.nix
      #../zsh.nix
      ../apps.nix
  ];
# Other stuff here
}
