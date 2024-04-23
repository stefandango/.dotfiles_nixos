{ lib, inputs, nixpkgs, nixpkgs-unstable, home-manager, nixvim, darwin, vars }:

let
system = "x86_64-darwin";
pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
};
unstable = import nixpkgs-unstable {
	inherit system;
	config.allowUnfree = true;
};


lib = nixpkgs.lib;
in
{
    Stefans-MacBook-Pro = darwin.lib.darwinSystem {

        inherit system;

        specialArgs =  {
            inherit inputs system unstable vars;
        };
        modules = [
            ./configuration.nix
            home-manager.darwinModules.home-manager {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.stefan.imports = [
                    inputs.nixvim.homeManagerModules.nixvim
                        ../nix/nvim.nix
                        ({pkgs, ...}: {

                         home.stateVersion = "23.11";
                         home.packages = with pkgs; [
                         ripgrep
                         curl
                         btop
                         ];
                         programs.bat.enable = true;
                         programs.bat.config.theme = "TwoDark";
                         programs.zsh.shellAliases = {
                         nixswitch = "darwin-rebuild switch --flake ~/Dev/.dotfiles_nixos/.#";
                         nixup = "pushd ~/Dev/.dotfiles_nixos; nix flake update; nixswitch; popd";
                         };
                         })

                ];
            }

        ];
    };
}
