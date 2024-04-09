{ config, lib, inputs, pkgs, home-manager, nixvim, darwin, vars, ... }:

let
system = "x86_64-darwin";
terminal = pkgs.${vars.terminal};
in
{
    imports =
    [ 
      inputs.home-manager.darwinModules.home-manager    
      #../theme/theming.nix
      #../modules/git.nix
      #../modules/kitty.nix
      #../modules/zsh.nix
    ];
  users.users.user.home = "/Users/user";

    # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  #nix.package = pkgs.nix;
  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "x86_64-darwin";

    nix = {
		settings = {
			experimental-features = "nix-command flakes";
			auto-optimise-store = true;
		};
#		gc = {
#			automatic = true;
#			dates = "weekly";
#			options = "--delete-older-than 2d";
#		};
	};
}