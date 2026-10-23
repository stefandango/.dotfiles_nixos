{
	description = "Stefan's unified Nix configuration for Linux and macOS";

	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

		# TEMP[hunk-darwin-nixpkgs]: hunk follows 26.05 rather than our unstable nixpkgs
		# TEMP-CHECK: nix_input_missing hunk 'x86_64-darwin'
		# Last nixpkgs line that still supports x86_64-darwin (26.11 dropped it and now
		# throws on import for that platform). hunk's flake-parts systems list includes
		# x86_64-darwin, so following our unstable nixpkgs breaks eval of the whole
		# Darwin config. Drop once hunk stops claiming that platform.
		nixpkgs-darwin-stable.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

		# TEMP[insync-nixpkgs-pin]: insync comes from the last nixpkgs where it built
		# TEMP-CHECK: grep -q '\.debug' "$(_flake_eval .inputs.nixpkgs.outPath)/pkgs/by-name/in/insync/package.nix"
		# insync 3.9.11 (nixpkgs 80bfecb7946b) ships a stub QtWebEngineProcess.debug
		# ELF that autoPatchelfHook dies on ("patchelf: data offset extends past file
		# end"), and even with it deleted the result segfaults until patchelf carries
		# NixOS/patchelf#672 -- NixOS/nixpkgs#576779. This rev is our previous lock,
		# which builds insync 3.9.8. Only modules/nixos/hyprland.nix uses it. The check
		# is a heuristic: it fires once insync's package.nix mentions .debug at all.
		nixpkgs-insync.url = "github:NixOS/nixpkgs/e7439b6b14ad3cc35d05608ebca9bce01a25f5f8";

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

		# The desktop shell: one Quickshell process for bar, notifications,
		# launcher, OSD, lock, polkit and wallpaper. Configured in
		# modules/nixos/dms.nix.
		dank-material-shell = {
			url = "github:AvengeMedia/DankMaterialShell";
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