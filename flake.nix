{
	description = "My nix configuration for both linux and macos setups...";

	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
		nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

		home-manager = {
				url = "github:nix-community/home-manager";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		nixvim = {
			url = "github:nix-community/nixvim";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		darwin = {
      		url = "github:lnl7/nix-darwin";
      		inputs.nixpkgs.follows = "nixpkgs";
    	};
	};

	outputs = inputs @ { self, darwin, nixpkgs, nixpkgs-unstable, home-manager, nixvim, ... }:

	let
	vars = {
		user = "stefan";
		location = "$HOME/.dotfiles";
		terminal = "kitty";
		editor = "nvim";
	};
	in
	{
		nixosConfigurations = (
			import ./configuration/nixos {
			inherit (nixpkgs) lib;
			inherit inputs nixpkgs nixpkgs-unstable home-manager nixvim vars;
			}
		);

		darwinConfigurations = (
			import ./configuration/darwin {
				inherit (nixpkgs) lib;
				inherit inputs nixpkgs nixpkgs-unstable home-manager nixvim darwin vars;
			}
		);
	};

}
