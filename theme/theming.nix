#
#  GTK
#

{ pkgs, vars, ... }:

{
  home-manager.users.${vars.user} = {
    home = {
      pointerCursor = {                     # System-Wide Cursor
        gtk.enable = true;
        name = "Dracula-cursors";
        package = pkgs.dracula-theme;
        size = 16;
      };
    };

    gtk = {                                 # Theming
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

    qt.enable = true;
    qt.platformTheme.name = "gtk";
  };

  environment.variables = {
    QT_QPA_PLATFORMTHEME="gtk2";
  };
}
