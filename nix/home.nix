{ config, pkgs, ... }:

{
	home.username = "stefan";
	home.homeDirectory = "/home/stefan";

	home.packages = [];

	home.stateVersion = "23.11";

	programs.home-manager.enable = true;

}
