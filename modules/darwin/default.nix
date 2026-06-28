
{ lib, inputs, pkgs, ...}:
{
  # Darwin-specific home-manager modules
  imports = [
    ./ntfy.nix
  ];
}

