#
#  GTK Theming - Home Manager Module
#

{ lib, pkgs, ... }:

{
  # System-wide cursor (Linux only)
  home.pointerCursor = lib.mkIf pkgs.stdenv.isLinux {
    gtk.enable = true;
    name = "Dracula-cursors";
    package = pkgs.dracula-theme;
    size = 16;
  };

  # GTK theming (Linux only)
  gtk = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    theme = {
      name = "Orchis-Dark-Compact";
      package = pkgs.orchis-theme;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    font = {
      name = "MonoLisa Nerd Font Semi-Bold";
    };
  };

  # Qt theming (Linux only)
  qt = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    platformTheme.name = "gtk";
  };
}
