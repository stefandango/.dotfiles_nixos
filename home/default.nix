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
    # Development tools
    gopls         # Go language server

    # Modern CLI tools
    zoxide        # Smarter cd command (learns your habits)
    delta         # Beautiful git diffs

    # System utilities
    curl
    btop
  ];

  # Enable home-manager
  programs.home-manager.enable = true;
}