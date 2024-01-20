{ lib, inputs, config, nixpkgs, vars, ... }:

{
	home.username = "stefan";
	home.homeDirectory = "/home/stefan";
	home.packages = [];
	
	xdg.enable = true;
	programs.home-manager.enable = true;
}
