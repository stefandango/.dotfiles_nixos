{
	description = "Stefan's unified Nix configuration for Linux and macOS";

	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

		# Last nixpkgs line that still supports x86_64-darwin (26.11 dropped it and
		# now throws on import for that platform). Used for two things, both Darwin:
		#   1. hunk's nixpkgs — its flake-parts systems list includes x86_64-darwin,
		#      so following our unstable nixpkgs breaks eval of the whole Darwin config.
		#   2. terminal-notifier — its build is broken on 26.11/aarch64-darwin (cctools
		#      ld crashes) and it isn't in the cache, so we overlay it in from here.
		# Both should go away once upstream catches up; see modules/darwin/ntfy.nix.
		nixpkgs-darwin-stable.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

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

		zen-browser = {
			url = "github:0xc000022070/zen-browser-flake";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		nix-claude-code = {
			url = "github:ryoppippi/nix-claude-code";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		mcp-nixos = {
			url = "github:utensils/mcp-nixos";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		herdr = {
			url = "github:ogulcancelik/herdr/v0.6.6";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		# Deliberately does NOT follow nixpkgs — see nixpkgs-darwin-stable above.
		hunk = {
			url = "github:modem-dev/hunk";
			inputs.nixpkgs.follows = "nixpkgs-darwin-stable";
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
				specialArgs = { inherit inputs vars; };
				modules = [
					{ nixpkgs.hostPlatform = "aarch64-darwin"; }
					# terminal-notifier (used by modules/darwin/ntfy.nix) fails to link on
					# nixpkgs 26.11/aarch64-darwin — cctools ld dies with SIGTRAP — and it
					# isn't in the binary cache, so the build is unavoidable. Take it from
					# 26.05, where it's cached and working. Drop once 26.11 builds it.
					{
						nixpkgs.overlays = [
							(final: prev: {
								inherit (import inputs.nixpkgs-darwin-stable {
									inherit (prev.stdenv.hostPlatform) system;
									config.allowUnfree = true;
								}) terminal-notifier;
							})
						];
					}
					./hosts/macbook
					./modules/shared/system.nix
					./modules/darwin
					home-manager.darwinModules.home-manager {
						home-manager.useGlobalPkgs = true;
						home-manager.useUserPackages = true;
						home-manager.backupFileExtension = "backup";
						home-manager.extraSpecialArgs = { inherit inputs vars; };
						home-manager.users.${vars.user} = import ./home;
					}
				];
			};
		};

		nixosConfigurations = {
			stefan = nixpkgs.lib.nixosSystem {
				specialArgs = { inherit inputs vars; };
				modules = [
					{ nixpkgs.hostPlatform = "x86_64-linux"; }
					# Disable openldap's flaky syncreplication test suite. The
					# i686-linux build is pulled in transitively via lutris's
					# 32-bit FHS env, and test017-syncreplication-refresh
					# times out on busy machines (well-known nixpkgs issue).
					{
						nixpkgs.overlays = [
							(final: prev: {
								openldap = prev.openldap.overrideAttrs (_: { doCheck = false; });
							})
						];
					}
					./hosts/nixos-desktop
					./modules/shared/system.nix
					./modules/nixos
					home-manager.nixosModules.home-manager {
						home-manager.useGlobalPkgs = true;
						home-manager.useUserPackages = true;
						home-manager.backupFileExtension = "backup";
						home-manager.extraSpecialArgs = { inherit inputs vars; };
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