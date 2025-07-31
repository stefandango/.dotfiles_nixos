{ lib, ... }:

{
  # Helper function to create system configurations
  mkSystem = { system, modules, specialArgs ? {} }:
    if (lib.hasSuffix "darwin" system) then
      # Darwin system
      inputs.darwin.lib.darwinSystem {
        inherit system;
        specialArgs = specialArgs;
        modules = modules ++ [
          ../modules/shared/system.nix
          ../modules/darwin
        ];
      }
    else
      # NixOS system  
      lib.nixosSystem {
        inherit system;
        specialArgs = specialArgs;
        modules = modules ++ [
          ../modules/shared/system.nix
          ../modules/nixos
        ];
      };

  # Helper to create host configurations
  mkHost = { hostname, system, modules ? [], extraModules ? [] }:
    {
      ${hostname} = mkSystem {
        inherit system;
        modules = modules ++ extraModules ++ [
          ../hosts/${hostname}
        ];
        specialArgs = {
          inherit inputs system vars;
        };
      };
    };

  # Cross-platform package sets
  commonPackages = pkgs: with pkgs; [
    # Development
    go
    nodejs_22
    python3
    rustup
    
    # Tools
    jq
    tmux
  ];

  # Platform-specific package sets
  darwinPackages = pkgs: with pkgs; [
    # macOS specific
  ];

  nixosPackages = pkgs: with pkgs; [
    # Linux specific
    firefox
    vlc
  ];
}