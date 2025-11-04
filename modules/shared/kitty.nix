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

      # Enhanced clipboard integration
      clipboard_control = "write-clipboard write-primary read-clipboard read-primary";

      # Allow remote control for better integration with tools
      allow_remote_control = "yes";
      listen_on = "unix:/tmp/kitty";
    };
    extraConfig = ''
      font_features MonoLisa-Medium +zero +ss04 +ss07 +ss08 +ss09
      font_features MonoLisa-MediumItalic +zero +ss04 +ss07 +ss08 +ss09

      # Clipboard shortcuts
      map cmd+c copy_to_clipboard
      map cmd+v paste_from_clipboard
      map shift+insert paste_from_clipboard

      # Additional clipboard operations
      map cmd+shift+v paste_from_selection
    '';
  };
}
