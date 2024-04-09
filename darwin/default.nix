{ lib, inputs, nixpkgs, home-manager, nixvim, darwin, vars }:

let
	system = "x86_64-darwin";
	pkgs = import nixpkgs {
		inherit system;
		config.allowUnfree = true;
	};

	lib = nixpkgs.lib;
	in
	{
		stefanMac = darwin.lib.darwinSystem {
			inherit system;
			specialArgs =  {
				inherit inputs system vars;
			};
			modules = [ 
				./configuration.nix 
				home-manager.darwinModules.home-manager {
					home-manager.useGlobalPkgs = true;
					home-manager.useUserPackages = true;
				}

			];
		};
	}