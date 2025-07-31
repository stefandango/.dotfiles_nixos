{ lib, inputs, nixpkgs, home-manager, nixvim, vars }:

let
	system = "x86_64-linux";
	pkgs = import nixpkgs {
		inherit system;
		config.allowUnfree = true;
	};

	lib = nixpkgs.lib;
	in
	{
		stefan = lib.nixosSystem {
			inherit system;
			specialArgs =  {
				inherit inputs system vars;
			};
			modules = [
				./configuration.nix
				home-manager.nixosModules.home-manager {
					home-manager.useGlobalPkgs = true;
					home-manager.useUserPackages = true;
				}

			];
		};
	}
