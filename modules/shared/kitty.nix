{ config, pkgs, lib, ... }:

{
  programs.kitty = {
    enable = true;
    # No themeFile — colors below define the "Graphite" scheme directly. On Linux the
    # theme-switcher overrides these live via ~/.config/kitty/theme-override.conf
    # (included at the end of extraConfig); on macOS these settings are the source.
    settings = {
      confirm_os_window_close = 0;
      enable_audio_bell = "no";
      resize_debounce_time = "0";
      background_opacity = lib.mkForce "0.95";
      font_family = "MonoLisa Nerd Font SemiBold";
      font_size = if pkgs.stdenv.isDarwin then "16.0" else "14.0";

      # macOS: make the LEFT Option key send Alt/Meta (so Alt+g, Alt+c/v/x
      # bindings reach zsh as ^[…). The RIGHT Option still types special
      # characters (é, ƒ, …). No-op on Linux.
      macos_option_as_alt = "left";

      # ── Graphite palette — near-greyscale base, muted ANSI (legible, not garish) ──
      background = "#131316";
      foreground = "#c6c6cd";
      cursor = "#c6c6cd";
      cursor_text_color = "#131316";
      selection_background = "#2a2a30";
      selection_foreground = "#c6c6cd";
      url_color = "#6f8fb3";
      # normal
      color0 = "#1c1c20"; # black
      color1 = "#b56b6b"; # red    (danger)
      color2 = "#7d9a6b"; # green  (success)
      color3 = "#c2a15c"; # yellow (warning)
      color4 = "#6f8fb3"; # blue   (accent)
      color5 = "#8c7da0"; # magenta (muted)
      color6 = "#6fa3a3"; # cyan   (muted teal)
      color7 = "#a8a8b0"; # white  (light grey)
      # bright
      color8  = "#4a4a52"; # bright black (grey)
      color9  = "#c47f7f"; # bright red
      color10 = "#8fab7c"; # bright green
      color11 = "#d4b36e"; # bright yellow
      color12 = "#84a1c4"; # bright blue
      color13 = "#9d8eb0"; # bright magenta
      color14 = "#80b3b3"; # bright cyan
      color15 = "#c6c6cd"; # bright white (fg)

      # Window padding (top right bottom left)
      window_padding_width = "10 20 10 40";

      # Enhanced clipboard integration
      clipboard_control = "write-clipboard write-primary read-clipboard read-primary";

      # Allow remote control for better integration with tools
      allow_remote_control = "yes";
      listen_on = "unix:/tmp/kitty";
    };
    extraConfig = ''
      # Load theme override from theme switcher (overrides themeFile colors)
      include ~/.config/kitty/theme-override.conf

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
