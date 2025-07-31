{
	description = "Stefan's unified Nix configuration for Linux and macOS";

	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

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

	outputs = inputs @ { self, nixpkgs, home-manager, nixvim, darwin, ... }:
	let
		# Global variables
		vars = {
			user = "stefan";
			location = "$HOME/.dotfiles";
			terminal = "kitty";
			editor = "nvim";
		};

		# Standard lib functions
		
		# Systems we support
		systems = [ "x86_64-linux" "aarch64-darwin" ];
		
		# Helper to generate pkgs for each system
		forAllSystems = nixpkgs.lib.genAttrs systems;
		pkgsFor = forAllSystems (system: import nixpkgs {
			inherit system;
			config.allowUnfree = true;
		});

	in {
		# Host configurations
		darwinConfigurations = {
			"Stefans-MacBook-Pro" = darwin.lib.darwinSystem {
				system = "aarch64-darwin";
				specialArgs = { inherit inputs vars; };
				modules = [
					./hosts/macbook
					./modules/shared/system.nix
					./modules/darwin
					home-manager.darwinModules.home-manager {
						home-manager.useGlobalPkgs = true;
						home-manager.useUserPackages = true;
						home-manager.extraSpecialArgs = { inherit vars; };
						home-manager.users.${vars.user} = import ./home;
					}
				];
			};
		};

		nixosConfigurations = {
			stefan = nixpkgs.lib.nixosSystem {
				system = "x86_64-linux";
				specialArgs = { inherit inputs vars; };
				modules = [
					./hosts/nixos-desktop
					./modules/shared/system.nix
					./modules/nixos
					home-manager.nixosModules.home-manager {
						home-manager.useGlobalPkgs = true;
						home-manager.useUserPackages = true;
						home-manager.extraSpecialArgs = { inherit vars; };
						home-manager.users.${vars.user} = import ./home;
					}
				];
			};
		};

		# Development shells for each system
		devShells = forAllSystems (system: {
			default = pkgsFor.${system}.mkShell {
				buildInputs = with pkgsFor.${system}; [
					nixpkgs-fmt
					nil
				];
			};
		});

		# Packages we can build
		packages = forAllSystems (system: {
			# Add custom packages here
		});
	};
}