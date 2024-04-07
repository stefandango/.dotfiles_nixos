{ config, lib, inputs, pkgs, home-manager, nixvim, darwin, vars, ... }:

let
system = "x86_64-darwin";
terminal = pkgs.${vars.terminal};
in
{
    imports =
    [ 
      inputs.home-manager.nixosModules.home-manager    
      ../modules/env.nix
      ../theme/theming.nix
      ../modules/git.nix
      ../modules/kitty.nix
      ../modules/zsh.nix
    ];
  users.users.user.home = "/Users/user";
      environment = {
  variables = {
		TERMINAL = "${vars.terminal}";
		EDITOR = "${vars.editor}";
		VISUAL = "${vars.editor}";
	};

    # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  nix.package = pkgs.nix;
}