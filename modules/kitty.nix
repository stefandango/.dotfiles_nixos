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
		background_opacity = lib.mkForce "0.8";
		font_family = "MonoLisa Nerd Font SemiBold";
		font_size = "12.0";
        };
	extraConfig = "font_features MonoLisaNF-SemiBoldRegular +zero +ss04 +ss07 +ss08 +ss09\nfont_features MonoLisaNF-SemiBoldItalic +zero +ss04 +ss07 +ss08 +ss09\nurl_style double";
      };
    };
  };
}
