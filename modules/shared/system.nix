{ lib, pkgs, vars, ... }:

{
  # Common Nix settings for both Darwin and NixOS
  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      substituters = [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };
  };

  # Common environment variables
  environment.variables = {
    EDITOR = vars.editor;
    TERMINAL = vars.terminal;
    QT_QPA_PLATFORMTHEME = "gtk2";
  };

  # Cross-platform core packages
  environment.systemPackages = with pkgs; [
    # Essential tools
    coreutils
    curl
    git
    tree
    wget
    unzip
    zip
    
    # Development tools
    direnv
    nix-direnv
    
    # Modern CLI tools
    btop
    ripgrep
  ];
}