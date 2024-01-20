{ lib, inputs, pkgs, ...}:

let
	system = "x86_64-linux";
	#pkgs= pkgs.legacyPackages.${system};
in
{
  # You can import other home-manager modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/home-manager):
    # outputs.homeManagerModules.example

    # Or modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default

    # You can also split up your configuration and import pieces of it here:
    inputs.nixvim.homeManagerModules.nixvim
    ./nvim.nix
  ];
  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.username = "stefan";
  home.homeDirectory = "/home/stefan";
  home.packages = [];
  home.stateVersion = "23.11";

  xdg.enable = true;
}

