{ lib, inputs, nixpkgs, nixpkgs-unstable, home-manager, nixvim, darwin, vars }:

let
system = "aarch64-darwin";
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
                home-manager.users.stefan = {
                    home.stateVersion = "23.11";
                };
                home-manager.users.stefan.imports = [
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
                         nixswitch = "darwin-rebuild switch --flake ~/.dotfiles/.#";
                         nixup = "pushd ~/.dotfiles; nix flake update; nixswitch; popd";
                         };
                         })

                ];
            }

        ];
    };
}
