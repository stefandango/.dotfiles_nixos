{ lib, inputs, pkgs, ...}:
{
  # You can import other home-manager modules here
  imports = [
    ./git.nix
    ./zsh.nix
  ];
# Other stuff here
}
