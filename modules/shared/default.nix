{ lib, inputs, pkgs, ...}:
{
  # You can import other home-manager modules here
  imports = [
    ./git.nix
    ./zsh.nix
    ./kitty.nix
  ];
# Other stuff here
}
