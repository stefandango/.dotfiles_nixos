{ config, pkgs, ... }:

{
	home.username = "stefan";
	home.homeDirectory = "/home/stefan";

	home.packages = [];

	home.stateVersion = "23.11";
	xdg.enable = true;
	programs.home-manager.enable = true;

}
