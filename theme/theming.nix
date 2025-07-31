#
#  GTK Theming - Home Manager Module
#

{ lib, pkgs, ... }:

{
  # NOTE: GTK theming disabled due to configuration issues
  # Uncomment and configure when ready to use
  
  # gtk = lib.mkIf pkgs.stdenv.isLinux {
  #   enable = true;
  #   
  #   theme = {
  #     name = "Adwaita-dark";
  #   };
  #   
  #   iconTheme = {
  #     name = "Adwaita";
  #   };
  # };

  # qt = lib.mkIf pkgs.stdenv.isLinux {
  #   enable = true;
  #   platformTheme.name = "gtk";
  # };
}
