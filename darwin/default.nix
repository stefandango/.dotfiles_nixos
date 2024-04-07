{ lib, inputs, nixpkgs, home-manager, nixvim, darwing, vars }:

let
	system = "x86_64-darwin";
	pkgs = import nixpkgs {
		inherit system;
		config.allowUnfree = true;
	};

	lib = nixpkgs.lib;
	in
	{
		stefanMac = lib.nixosSystem {
			inherit system;
			specialArgs =  {
				inherit inputs system unstable hyprland vars;
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
