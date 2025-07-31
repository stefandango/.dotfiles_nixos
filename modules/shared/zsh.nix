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
  ];

  home.file = {
    "Scripts/tmux-sessionizer" = {
      source = ../scripts/tmux-sessionizer;
      recursive = true;
      executable = true;
    };

    ".config/oh-my-posh/ohmyposhv3-v2.json" = {
      source = ../config/ohmyposhv3-v2.json;
      recursive = true;
    };

    ".omnisharp/omnisharp.json" = {
      source = ../config/omnisharp.json;
      recursive = true;
    };

    ".config/lsd/colors.yaml" = {
      source = ../config/lsdtheme.yaml;
      recursive = true;
    };

    ".config/lsd/config.yaml" = {
      source = ../config/lsdconfig.yaml;
      recursive = true;
    };
  };

  programs.zsh = {
    enable = true;
    dotDir = ".config/zsh";
    shellAliases = {
      ls = "lsd";
      la = "lsd -al";
      ll = "lsd -l";
      claude = "/Users/stefan/.claude/local/claude";
      nixbuild = "nix build ~/.dotfiles#darwinConfigurations.Stefans-MacBook-Pro.system";
      nixcheck = "darwin-rebuild check --flake ~/.dotfiles#Stefans-MacBook-Pro";
      nixswitch = "sudo darwin-rebuild switch --flake ~/.dotfiles#Stefans-MacBook-Pro";
      nixup = "pushd ~/.dotfiles; nix flake update; nixswitch; popd";
    };
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
      export PATH="$PATH:/home/stefan/.dotnet/tools:/Users/stefan/.dotnet/tools"
      
      bindkey -s ^f '~/Scripts/tmux-sessionizer\n'
      
      eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/ohmyposhv3-v2.json)"
    '';
  };

  programs.tmux = {
    enable = true;
    prefix = "C-a";
    baseIndex = 1;
    keyMode = "vi";
    mouse = false;
    terminal = "screen-256color";
    extraConfig = ''
      # Increase tmux messages display duration from 750ms to 4s
      set -g display-time 4000
      set -s escape-time 0
      
      # Renumber windows automatically
      set-option -g renumber-windows on
      
      # Easier and faster switching between next/prev window
      bind C-p previous-window
      bind C-n next-window
      bind-key -r f run-shell "tmux neww ~/Scripts/tmux-sessionizer"
      
      # Light & Transparent Tokyo Night Theme
      set -g status-position bottom
      set -g status-justify centre
      set -g status-style bg=default,fg=#a9b1d6
      set -g status-left-length 80
      set -g status-right-length 80
      
      # Minimal left status: just session name
      set -g status-left "#[fg=#7aa2f7,bold] #S #[fg=#565f89]│ "
      
      # Minimal right status: path and time
      set -g status-right "#[fg=#565f89]#{b:pane_current_path} #[fg=#565f89]│ #[fg=#7aa2f7]%H:%M"
      
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