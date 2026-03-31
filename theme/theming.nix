#
#  GTK Theming - Home Manager Module
#

{ lib, pkgs, ... }:

{
  # GTK theming for Linux (only available in home-manager)
  home.packages = lib.mkIf pkgs.stdenv.isLinux (with pkgs; [
    adwaita-icon-theme
    gnome-themes-extra
    bibata-cursors
  ]);

  home.pointerCursor = lib.mkIf pkgs.stdenv.isLinux {
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 28;
    gtk.enable = true;
  };

  gtk = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;

    theme = {
      name = "Adwaita-dark";
    };

    gtk4.theme = null;

    iconTheme = {
      name = "Adwaita";
    };
  };

  qt = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    platformTheme.name = "gtk";
  };

  # Font configuration for better rendering
  fonts.fontconfig = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    defaultFonts = {
      monospace = [ "MonoLisa Nerd Font" "JetBrainsMono Nerd Font" "FiraCode Nerd Font" ];
      sansSerif = [ "Noto Sans" ];
      serif = [ "Noto Serif" ];
    };
  };
}
