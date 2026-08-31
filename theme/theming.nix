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
    # DMS's scripts/gtk.sh copies this out of the store into
    # ~/.local/share/themes and splices matugen's colours into its gtk.css.
    # It patches adw-gtk3 specifically — stock Adwaita has no seam for it.
    adw-gtk3
  ]);

  home.pointerCursor = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 28;
    gtk.enable = true;
  };

  gtk = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;

    # Global UI font for GTK apps — this is what Firefox's chrome (toolbar,
    # tabs, menus), the file manager, etc. follow. Electron apps (Obsidian,
    # VS Code) do NOT read this; set their font in-app.
    font = {
      name = "Inter";
      size = 11;
    };

    # adw-gtk3-dark, not Adwaita-dark: GTK searches $XDG_DATA_HOME/themes
    # first, so this resolves to the user copy DMS patches with the matugen
    # palette rather than the pristine one in the store.
    #
    # Nothing here may manage gtk-3.0/gtk.css or gtk-4.0/gtk.css — DMS writes
    # both, and gtk.sh bails out ("user-managed symlink") if it finds a
    # home-manager symlink there. So no gtk.extraCss / gtk3.extraCss.
    theme = {
      name = "adw-gtk3-dark";
    };

    # libadwaita apps ignore the theme name and follow the @import DMS injects
    # into gtk-4.0/gtk.css, so there is nothing to name here.
    gtk4.theme = null;

    iconTheme = {
      name = "Adwaita";
    };
  };

  # Qt reads its palette from GTK3, which is adw-gtk3-dark carrying matugen's
  # colours. This is the only place the Qt platform theme is set — the NixOS
  # `qt` block in hosts/nixos-desktop/default.nix was removed because its
  # style = "adwaita-dark" exported QT_STYLE_OVERRIDE and overrode this.
  qt = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    platformTheme.name = "gtk3";
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
