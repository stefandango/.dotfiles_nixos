{ lib, inputs, pkgs, ...}:
{
  # Shared home-manager modules
  imports = [
    ./git.nix
    ./zsh.nix
    ./kitty.nix
  ];
}
