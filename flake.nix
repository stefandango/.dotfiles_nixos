{
	description = "My first flake... will be tweaked!!";

	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/release-23.11";
		nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

		home-manager = {
			url = "github:nix-community/home-manager/release-23.11";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		nixvim = {
			url = "github:nix-community/nixvim";
			inputs.nixpkgs.follows = "nixpkgs-unstable";
		};
		
		hyprland = {
			url = "github:hyprwm/Hyprland";
			inputs.nixpkgs.follows = "nixpkgs-unstable";
		};	
	};

	outputs = inputs @ { self, nixpkgs, nixpkgs-unstable, home-manager, nixvim, hyprland, ... }:

	let
	vars = {
		user = "stefan";
		location = "$HOME/.dotfiles_nixos";
		terminal = "kitty";
		editor = "nvim";
	};
	in
	{

		nixosConfigurations = (

			import ./configuration {	
			inherit (nixpkgs) lib;
			inherit inputs nixpkgs nixpkgs-unstable home-manager hyprland nixvim vars;
			}
			
		);
		homeConfiguration = (
			import ./nix {
				inherit (nixpkgs) lib;
				inherit inputs nixpkgs nixpkgs-unstable home-manager;
			}
		);
	};

}
