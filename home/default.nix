{ config, lib, pkgs, vars, ... }:

{
  # Home Manager configuration that works on both platforms
  home = {
    username = vars.user;
    homeDirectory = if pkgs.stdenv.isDarwin 
      then "/Users/${vars.user}"
      else "/home/${vars.user}";
    stateVersion = "23.11";
  };

  # Import shared home modules
  imports = [
    ../modules/shared/default.nix
    ../theme/theming.nix
  ];

  # Cross-platform home packages
  home.packages = with pkgs; [
    # Add user-specific packages here
    bat
    ripgrep
    curl
    btop
  ];

  # Enable home-manager
  programs.home-manager.enable = true;
}