#
#  GTK Theming - Home Manager Module
#

{ lib, pkgs, ... }:

{
  # GTK theming (Linux only)
  gtk = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    
    theme = {
      name = "Adwaita-dark";
    };
    
    iconTheme = {
      name = "Adwaita";
    };
  };

  # Qt theming (Linux only)  
  qt = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    platformTheme.name = "gtk";
  };
}
