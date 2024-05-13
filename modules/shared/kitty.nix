{ pkgs,lib, vars, ... }:

let
  colors = import ../theming/colors.nix;
in
{
  home-manager.users.${vars.user} = {
    programs = {
      kitty = {
        enable = true;
        theme = "Afterglow";
        settings = {
          confirm_os_window_close=0;
          enable_audio_bell="no";
          resize_debounce_time="0";
		      background_opacity = lib.mkForce "0.85";
		      font_family = "JetBrainsMonoNL Nerd Font Mono SemiBold";
          font_size = "16.0";

        };
	        extraConfig = ''
          font_features MonoLisa-Medium +zero +ss04 +ss07 +ss08 +ss09
          font_features MonoLisa-MediumItalic +zero +ss04 +ss07 +ss08 +ss09
          '';
      };
    };
  };
}
