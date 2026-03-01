{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    bat
    lsd
    oh-my-posh
    fzf
    ripgrep
    lazygit
    neovim-unwrapped
    fd
    tree-sitter
    gh
    codex
    tokei
    #opencode
  ];

  home.file = {
    "Scripts/tmux-sessionizer" = {
      source = ../scripts/tmux-sessionizer;
      executable = true;
    };

    "Scripts/projstats" = {
      source = ../scripts/projstats;
      executable = true;
    };

    "Scripts/nixswitch" = {
      source = ../scripts/nixswitch;
      executable = true;
    };

    "Scripts/nixup" = {
      source = ../scripts/nixup;
      executable = true;
    };

    "Scripts/tmux-battery" = {
      source = ../scripts/tmux-battery;
      executable = true;
    };

    "Scripts/checkport" = {
      source = ../scripts/checkport;
      executable = true;
    };

    "Scripts/killport" = {
      source = ../scripts/killport;
      executable = true;
    };

    "Scripts/serve" = {
      source = ../scripts/serve;
      executable = true;
    };

    "Scripts/json" = {
      source = ../scripts/json;
      executable = true;
    };

    "Scripts/copy" = {
      source = ../scripts/copy;
      executable = true;
    };

    "Scripts/paste" = {
      source = ../scripts/paste;
      executable = true;
    };

    "Scripts/copypath" = {
      source = ../scripts/copypath;
      executable = true;
    };

    "Scripts/clipwatch" = {
      source = ../scripts/clipwatch;
      executable = true;
    };

    "Scripts/clipclear" = {
      source = ../scripts/clipclear;
      executable = true;
    };

    "Scripts/clipshow" = {
      source = ../scripts/clipshow;
      executable = true;
    };

    "Scripts/myip" = {
      source = ../scripts/myip;
      executable = true;
    };

    "Scripts/localip" = {
      source = ../scripts/localip;
      executable = true;
    };

    "Scripts/speedtest" = {
      source = ../scripts/speedtest;
      executable = true;
    };

    "Scripts/netinfo" = {
      source = ../scripts/netinfo;
      executable = true;
    };

    "Scripts/nixclean" = {
      source = ../scripts/nixclean;
      executable = true;
    };

    "Scripts/nixgen" = {
      source = ../scripts/nixgen;
      executable = true;
    };

    "Scripts/nixsearch" = {
      source = ../scripts/nixsearch;
      executable = true;
    };

    "Scripts/nixinfo" = {
      source = ../scripts/nixinfo;
      executable = true;
    };

    "Scripts/nixvalidate" = {
      source = ../scripts/nixvalidate;
      executable = true;
    };

    "Scripts/tmux-quit" = {
      source = ../scripts/tmux-quit;
      executable = true;
    };

    ".config/oh-my-posh/ohmyposhv3-v2.json" = {
      source = ../config/ohmyposhv3-v2.json;
    };

    ".omnisharp/omnisharp.json" = {
      source = ../config/omnisharp.json;
    };

    ".config/lsd/colors.yaml" = {
      source = ../config/lsdtheme.yaml;
    };

    ".config/lsd/config.yaml" = {
      source = ../config/lsdconfig.yaml;
    };
  };

  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    shellAliases = {
      ls = "lsd";
      la = "lsd -al";
      ll = "lsd -l";

      # File management enhancements
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      cdtemp = "cd $(mktemp -d)";
      backup = "cp \"$1\" \"$1.backup.$(date +%Y%m%d_%H%M%S)\"";

      # Quick directory shortcuts
      dev = "cd ~/Dev";
      dots = "cd ~/.dotfiles";

      # Zoxide shortcuts (smarter cd)
      z = "zoxide";
      zi = "zoxide query -i";  # Interactive selection

      # Smart Nix helpers
      nixtest = "nix flake check ~/.dotfiles";

      # Enhanced clipboard shortcuts
      cb = "clipshow";          # Show clipboard contents
      cbw = "clipwatch";        # Watch clipboard changes
      cbc = "clipclear";        # Clear clipboard
      cbcp = "copypath";        # Copy current path

      # Quick pipe to clipboard
      clip = if pkgs.stdenv.isDarwin then "pbcopy" else "xclip -selection clipboard";
    } // (if pkgs.stdenv.isDarwin then {
      claude = "/Users/stefan/.claude/local/claude";
      nixbuild = "nix build ~/.dotfiles#darwinConfigurations.Stefans-MacBook-Pro.system";
      nixcheck = "darwin-rebuild check --flake ~/.dotfiles#Stefans-MacBook-Pro";
    } else {
      # claude alias removed - using system claude binary
      nixbuild = "nix build ~/.dotfiles#nixosConfigurations.stefan.config.system.build.toplevel";
      nixcheck = "sudo nixos-rebuild dry-build --flake ~/.dotfiles#stefan";
    });
    autosuggestion.enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    history = {
      size = 1000;
      save = 1000;
      share = true;
      ignoreAllDups = true;
    };
    historySubstringSearch = {
      enable = true;
    };
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "sudo"
        "azure"
        "docker"
        "docker-compose"
        "colored-man-pages"
        "command-not-found"
        "history"
        "copypath"
      ];
    };
    initContent = ''
      export PATH="$HOME/.local/bin:$PATH:/home/stefan/.dotnet/tools:/Users/stefan/.dotnet/tools:$HOME/Scripts:$HOME/go/bin"

      # Initialize zoxide (smarter cd)
      eval "$(zoxide init zsh)"

      # Tmux sessionizer
      bindkey -s ^f '~/Scripts/tmux-sessionizer\n'

      # Enhanced clipboard bindings
      bindkey -s '^[c' 'clipshow\n'        # Alt+c to show clipboard
      bindkey -s '^[v' 'paste\n'           # Alt+v to paste from clipboard
      bindkey -s '^[x' 'clipclear\n'       # Alt+x to clear clipboard

      # Quick clipboard functions
      cpwd() { pwd | clip && echo "📋 Copied current directory to clipboard"; }
      ccat() { cat "$1" | clip && echo "📋 Copied $1 to clipboard"; }

      eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/ohmyposhv3-v2.json)"
    '';
  };

  programs.tmux = {
    enable = true;
    prefix = "C-a";
    baseIndex = 1;
    keyMode = "vi";
    mouse = true;
    shell = "${pkgs.zsh}/bin/zsh";
    terminal = "screen-256color";
    extraConfig = ''
      # Enable 24-bit color and proper terminal support
      set-option -ga terminal-overrides ",*256col*:Tc"
      set-option -g default-terminal "screen-256color"

      # Increase tmux messages display duration from 750ms to 4s
      set -g display-time 4000
      set -s escape-time 0

      # Update status bar every 30 seconds for battery info
      set -g status-interval 30

      # Renumber windows automatically
      set-option -g renumber-windows on

      # Enhanced clipboard integration
      set -g set-clipboard on

      # Copy mode bindings for better clipboard integration
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi r send-keys -X rectangle-toggle

      # Platform-specific clipboard setup
      if-shell 'test "$(uname)" = "Darwin"' {
        set -s copy-command 'pbcopy'
        bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'pbcopy'
      } {
        if-shell 'command -v wl-copy >/dev/null 2>&1' {
          set -s copy-command 'wl-copy'
          bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'wl-copy'
        } {
          if-shell 'command -v xclip >/dev/null 2>&1' {
            set -s copy-command 'xclip -selection clipboard'
            bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'xclip -selection clipboard'
          }
        }
      }

      # Quick paste binding
      bind-key ] paste-buffer
      bind-key p paste-buffer

      # Easier and faster switching between next/prev window
      bind C-p previous-window
      bind C-n next-window
      bind-key -r f run-shell "tmux neww ~/Scripts/tmux-sessionizer"

      # Smart quit using tmux-quit script
      bind-key X run-shell '~/Scripts/tmux-quit'

      # Light & Transparent Tokyo Night Theme
      set -g status-position bottom
      set -g status-justify centre
      set -g status-style bg=default,fg=#a9b1d6
      set -g status-left-length 80
      set -g status-right-length 80

      # Minimal left status: just session name
      set -g status-left "#[fg=#7aa2f7,bold] #S #[fg=#565f89]│ "

      # Right status: battery, path and time
      set -g status-right "#(~/Scripts/tmux-battery) #[fg=#565f89]│ #[fg=#565f89]#{b:pane_current_path} #[fg=#565f89]│ #[fg=#7aa2f7]%H:%M"

      # Cleaner window status
      set -g window-status-style fg=#565f89,bg=default
      set -g window-status-current-style fg=#bb9af7,bg=default,bold
      set -g window-status-format " #I #W#{?window_zoomed_flag,󰊓,} "
      set -g window-status-current-format " #I #W#{?window_zoomed_flag,󰊓,} "

      # Light pane borders
      set -g pane-border-style fg=#414868
      set -g pane-active-border-style fg=#7aa2f7
      set -g pane-border-status off

      # Subtle message styling
      set -g message-style bg=#bb9af7,fg=#1a1b26,bold
      set -g message-command-style bg=#7aa2f7,fg=#1a1b26,bold

      # Light copy mode
      set -g mode-style bg=#bb9af7,fg=#1a1b26,bold

      # Clock styling
      set -g clock-mode-colour #7aa2f7
      set -g clock-mode-style 24

      # Pane indicators
      set -g display-panes-active-colour #7aa2f7
      set -g display-panes-colour #565f89
      set -g display-panes-time 1500
    '';
  };
}
