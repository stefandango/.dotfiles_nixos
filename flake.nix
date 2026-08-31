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
					# TEMP[openldap-nocheck]: openldap test suite disabled (flaky, no upstream fix to wait on)
					# TEMP-CHECK: recheck_after 2027-02-01
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
					# TEMP[font-manager-vala-dragicon]: patch font-manager's two DragIcon call sites
					# TEMP-CHECK: nix_pkg_cached x86_64-linux font-manager
					# font-manager 0.9.4 stopped compiling: Gtk.DragIcon.get_for_drag is a
					# constructor in the current vapi, so both call sites need `new`. Hydra
					# fails on it too, so there is no cached build to fall back to. Upstream
					# fix is FontManager PR #468; nixpkgs carries it in flight as PRs #556842
					# and #557155 — drop this block once one of those lands.
					{
						nixpkgs.overlays = [
							(final: prev: {
								font-manager = prev.font-manager.overrideAttrs (old: {
									patches = (old.patches or [ ]) ++ [
										(final.fetchpatch {
											name = "font-manager-vala-dragicon.patch";
											url = "https://github.com/FontManager/font-manager/commit/e2ad529a88929bbc76906ac78260dacf4d8c8c6b.patch";
											hash = "sha256-NmA9w61NRuoUG+Rnwpf0Q6OuDvf1eR/kdMJFApJwtCw=";
										})
									];
								});
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