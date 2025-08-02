{ config, pkgs, lib, ... }:

{
  programs.kitty = {
    enable = true;
    themeFile = "Afterglow";
    settings = {
      confirm_os_window_close = 0;
      enable_audio_bell = "no";
      resize_debounce_time = "0";
      background_opacity = lib.mkForce "0.95";
      font_family = "MonoLisa Nerd Font SemiBold";
      font_size = if pkgs.stdenv.isDarwin then "16.0" else "14.0";
    };
    extraConfig = ''
      font_features MonoLisa-Medium +zero +ss04 +ss07 +ss08 +ss09
      font_features MonoLisa-MediumItalic +zero +ss04 +ss07 +ss08 +ss09
    '';
  };
}
