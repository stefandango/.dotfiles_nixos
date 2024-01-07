#
#  GTK
#

{ pkgs, vars, ... }:

{
  home-manager.users.${vars.user} = {
    home = {
      #file.".config/wall".source = ./wall;
      #file.".config/wall.mp4".source = ./wall.mp4;
      pointerCursor = {                     # System-Wide Cursor
        gtk.enable = true;
        name = "Dracula-cursors";
        #name = "volantes";
        package = pkgs.dracula-theme;
        #package = pkgs.volantes-cursors;
        size = 16;
      };
    };

    gtk = {                                 # Theming
      enable = true;
      theme = {
        #name = "Dracula";
        #name = "Catppuccin-Mocha-Compact-Blue-Dark";
        name = "Orchis-Dark-Compact";
	#name = "Nordic";
        #package = pkgs.dracula-theme;
        #package = pkgs.catppuccin-gtk.override {
        #   accents = ["blue"];
        #   size = "compact";
        #   variant = "mocha";
        # };
        package = pkgs.orchis-theme;
	#package = pkgs.nordic;
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
    qt.platformTheme = "gtk";
    #gt.style.name = "adwaita-dark";
    #qt.style.package = pkgs.adwaita-qt;
  };

  environment.variables = {
    QT_QPA_PLATFORMTHEME="gtk2";
  };
}
