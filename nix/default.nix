{ lib, inputs, nixpkgs, home-manager, ...}:

let
	system = "x86_65-linux";
	pkgs= nixpkgs.legacyPackages.${system};
in
{
	stefan = home-manager.lib.homeManagerConfiguration {
		inherit pkgs;
		specialArgs = { inherit inputs };
		modules = [ 
			./home.nix 
			home = {
				username = "stefan"
				homeDirectory = "/home/stefan";
				packages = [
					pkgs.home-manager
				];
				stateVersion = "23.11";
			};
		];
	};
}
