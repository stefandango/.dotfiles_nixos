{ config, lib, inputs, pkgs, home-manager, nixvim, darwin, vars, ... }:

let
system = "x86_64-darwin";
terminal = pkgs.${vars.terminal};
in
{
    imports =
    [ 
      inputs.home-manager.darwinModules.home-manager    
      #../modules/git.nix
      #../modules/kitty.nix
      #../modules/zsh.nix
    ];
    users.users.stefan = {
      name = "stefan";
      home = "/Users/stefan";
    };
    programs.zsh.enable = true;
      environment = {
    shells = with pkgs; [ bash zsh ];
    loginShell = pkgs.zsh;
    systemPackages = [ pkgs.coreutils ];
    systemPath = [ "/opt/homebrew/bin" ];
    pathsToLink = [ "/Applications" ];
  };

    # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  #nix.package = pkgs.nix;
  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "x86_64-darwin";
  system.stateVersion = 4;

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  ''; 

}