{ lib, pkgs, ... }:

let
  colors = import ../../theme/colors.nix;

  regreetCSS = with colors.scheme.default; ''
    window {
      background-color: rgba(${rgb.bg}, 0.85);
      color: #${hex.fg};
    }

    #body {
      background-color: rgba(${rgb.bg}, 0.7);
      border-radius: 12px;
      padding: 48px;
      border: 2px solid rgba(${rgb.blue}, 0.6);
      box-shadow: 0 8px 32px rgba(0, 0, 0, 0.6);
    }

    entry {
      background-color: rgba(0, 0, 0, 0.6);
      color: #${hex.fg};
      border: 2px solid rgba(${rgb.blue}, 0.8);
      border-radius: 8px;
      padding: 12px 16px;
      font-size: 16px;
      caret-color: #${hex.blue};
      min-height: 20px;
    }

    entry:focus {
      border-color: #${hex.blue};
      box-shadow: 0 0 12px rgba(${rgb.blue}, 0.3);
    }

    button {
      background-color: rgba(${rgb.blue}, 0.2);
      color: #${hex.fg};
      border: 1px solid rgba(${rgb.blue}, 0.5);
      border-radius: 8px;
      padding: 8px 24px;
      font-size: 14px;
      font-weight: bold;
    }

    button:hover {
      background-color: rgba(${rgb.blue}, 0.4);
      border-color: #${hex.blue};
    }

    button:active {
      background-color: rgba(${rgb.blue}, 0.6);
    }

    combobox button {
      background-color: rgba(0, 0, 0, 0.4);
      border: 1px solid rgba(${rgb.gray}, 0.5);
    }

    label {
      color: #${hex.fg};
      font-size: 14px;
    }

    #error-label {
      color: #${hex.red};
      font-weight: bold;
    }
  '';
in
{
  programs.regreet = {
    enable = true;

    cageArgs = [ "-s" "-d" "-m" "last" ];

    settings = {
      background = {
        path = "/var/lib/regreet/greeter-wallpaper.jpg";
        fit = "Cover";
      };
      GTK = {
        application_prefer_dark_theme = true;
      };
      commands = {
        reboot = [ "systemctl" "reboot" ];
        poweroff = [ "systemctl" "poweroff" ];
      };
    };

    extraCss = regreetCSS;

    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };

    font = {
      name = "JetBrainsMono Nerd Font";
      package = pkgs.nerd-fonts.jetbrains-mono;
      size = 14;
    };

    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
    };
  };

  # Ensure regreet can find wayland session .desktop files
  systemd.services.greetd.environment = {
    XDG_DATA_DIRS = "/run/current-system/sw/share";
  };

  # Preserve systemd service settings for clean boot
  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal";
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };
}
