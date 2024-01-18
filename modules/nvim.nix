{ lib, pkgs, vars, nixvim, ... }:

let
	colors = import ../theme/colors.nix;
in
{
	programs.nixvim = {
		enable = true;
		viAlias = true;
		vimAlias = true;
		defaultEditor = true;
	};
}
