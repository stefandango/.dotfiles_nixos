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
    
    "Scripts/nixswitch" = {
      text = if pkgs.stdenv.isDarwin then ''
        #!/usr/bin/env bash
        darwin-rebuild switch --flake ~/.dotfiles#Stefans-MacBook-Pro "$@"
      '' else ''
        #!/usr/bin/env bash
        sudo nixos-rebuild switch --flake ~/.dotfiles#stefan "$@"
      '';
      executable = true;
    };
    
    "Scripts/nixup" = {
      text = ''
        #!/usr/bin/env bash
        pushd ~/.dotfiles
        nix flake update
        ~/Scripts/nixswitch
        popd
      '';
      executable = true;
    };
    
    "Scripts/tmux-battery" = {
      text = ''
        #!/usr/bin/env bash
        
        # Cross-platform battery script for tmux
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS using pmset
            battery_info=$(pmset -g batt)
            if echo "$battery_info" | grep -q "Battery Power"; then
                percentage=$(echo "$battery_info" | grep -o '[0-9]\+%' | head -n 1)
                percentage_num=$(echo "$percentage" | tr -d '%')
                
                if echo "$battery_info" | grep -q "charging"; then
                    icon="󰂄"
                    color="#40c4ff"
                elif [[ $percentage_num -le 20 ]]; then
                    icon="󰁺"
                    color="#f7768e"
                elif [[ $percentage_num -le 50 ]]; then
                    icon="󰁾"
                    color="#e0af68"
                else
                    icon="󰁹"
                    color="#9ece6a"
                fi
                
                echo "#[fg=$color]$icon $percentage"
            fi
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux using /sys/class/power_supply
            if [[ -d "/sys/class/power_supply/BAT0" ]]; then
                capacity=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo "0")
                status=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo "Unknown")
                
                if [[ "$status" == "Charging" ]]; then
                    icon="󰂄"
                    color="#40c4ff"
                elif [[ $capacity -le 20 ]]; then
                    icon="󰁺"
                    color="#f7768e"
                elif [[ $capacity -le 50 ]]; then
                    icon="󰁾"
                    color="#e0af68"
                else
                    icon="󰁹"
                    color="#9ece6a"
                fi
                
                echo "#[fg=$color]$icon $capacity%"
            fi
        fi
      '';
      executable = true;
    };

    # Development Environment Scripts
    "Scripts/checkport" = {
      text = ''
        #!/usr/bin/env bash
        # Check what's running on a specific port
        
        if [[ $# -eq 0 ]]; then
            echo "Usage: checkport <port>"
            echo "Example: checkport 3000"
            exit 1
        fi
        
        port=$1
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            result=$(lsof -i :$port -P -n 2>/dev/null)
            if [[ -n "$result" ]]; then
                echo "Port $port is in use:"
                echo "$result"
            else
                echo "Port $port is free"
            fi
        else
            # Linux
            result=$(ss -tulpn | grep ":$port ")
            if [[ -n "$result" ]]; then
                echo "Port $port is in use:"
                echo "$result"
            else
                echo "Port $port is free"
            fi
        fi
      '';
      executable = true;
    };

    "Scripts/killport" = {
      text = ''
        #!/usr/bin/env bash
        # Kill process using a specific port
        
        if [[ $# -eq 0 ]]; then
            echo "Usage: killport <port>"
            echo "Example: killport 3000"
            exit 1
        fi
        
        port=$1
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            pids=$(lsof -ti :$port 2>/dev/null)
        else
            # Linux  
            pids=$(ss -tulpn | grep ":$port " | awk '{print $7}' | cut -d',' -f2 | cut -d'=' -f2)
        fi
        
        if [[ -n "$pids" ]]; then
            echo "Killing processes on port $port: $pids"
            echo "$pids" | xargs kill -9 2>/dev/null
            echo "Done"
        else
            echo "No processes found on port $port"
        fi
      '';
      executable = true;
    };
    
    "Scripts/serve" = {
      text = ''
        #!/usr/bin/env bash
        # Start simple HTTP server in current directory
        
        port=''${1:-8000}
        
        echo "Starting HTTP server on port $port..."
        echo "Serving: $(pwd)"
        echo "URL: http://localhost:$port"
        echo "Press Ctrl+C to stop"
        echo ""
        
        if command -v python3 >/dev/null 2>&1; then
            python3 -m http.server $port
        elif command -v python >/dev/null 2>&1; then
            python -m SimpleHTTPServer $port
        else
            echo "Error: Python not found"
            exit 1
        fi
      '';
      executable = true;
    };
    
    "Scripts/json" = {
      text = ''
        #!/usr/bin/env bash
        # Pretty print JSON from stdin or file
        
        if [[ $# -eq 0 ]]; then
            # Read from stdin
            if command -v jq >/dev/null 2>&1; then
                jq .
            elif command -v python3 >/dev/null 2>&1; then
                python3 -m json.tool
            else
                echo "Error: jq or python3 required for JSON formatting"
                exit 1
            fi
        else
            # Read from file
            file="$1"
            if [[ ! -f "$file" ]]; then
                echo "Error: File '$file' not found"
                exit 1
            fi
            
            if command -v jq >/dev/null 2>&1; then
                jq . "$file"
            elif command -v python3 >/dev/null 2>&1; then
                python3 -m json.tool "$file"
            else
                echo "Error: jq or python3 required for JSON formatting"
                exit 1
            fi
        fi
      '';
      executable = true;
    };

    # Clipboard Integration Scripts
    "Scripts/copy" = {
      text = ''
        #!/usr/bin/env bash
        # Copy file contents or stdin to clipboard
        
        if [[ $# -eq 0 ]]; then
            # Read from stdin
            if [[ "$OSTYPE" == "darwin"* ]]; then
                pbcopy
            elif command -v xclip >/dev/null 2>&1; then
                xclip -selection clipboard
            elif command -v wl-copy >/dev/null 2>&1; then
                wl-copy
            else
                echo "Error: No clipboard tool found (pbcopy/xclip/wl-copy)"
                exit 1
            fi
        else
            # Read from file
            file="$1"
            if [[ ! -f "$file" ]]; then
                echo "Error: File '$file' not found"
                exit 1
            fi
            
            if [[ "$OSTYPE" == "darwin"* ]]; then
                pbcopy < "$file"
            elif command -v xclip >/dev/null 2>&1; then
                xclip -selection clipboard < "$file"
            elif command -v wl-copy >/dev/null 2>&1; then
                wl-copy < "$file"
            else
                echo "Error: No clipboard tool found (pbcopy/xclip/wl-copy)"
                exit 1
            fi
            
            echo "Copied contents of '$file' to clipboard"
        fi
      '';
      executable = true;
    };
    
    "Scripts/paste" = {
      text = ''
        #!/usr/bin/env bash
        # Paste clipboard contents to file or stdout
        
        if [[ $# -eq 0 ]]; then
            # Output to stdout
            if [[ "$OSTYPE" == "darwin"* ]]; then
                pbpaste
            elif command -v xclip >/dev/null 2>&1; then
                xclip -selection clipboard -o
            elif command -v wl-paste >/dev/null 2>&1; then
                wl-paste
            else
                echo "Error: No clipboard tool found (pbpaste/xclip/wl-paste)"
                exit 1
            fi
        else
            # Write to file
            file="$1"
            
            if [[ "$OSTYPE" == "darwin"* ]]; then
                pbpaste > "$file"
            elif command -v xclip >/dev/null 2>&1; then
                xclip -selection clipboard -o > "$file"
            elif command -v wl-paste >/dev/null 2>&1; then
                wl-paste > "$file"
            else
                echo "Error: No clipboard tool found (pbpaste/xclip/wl-paste)"
                exit 1
            fi
            
            echo "Pasted clipboard contents to '$file'"
        fi
      '';
      executable = true;
    };
    
    "Scripts/copypath" = {
      text = ''
        #!/usr/bin/env bash
        # Copy current directory path or specified path to clipboard
        
        if [[ $# -eq 0 ]]; then
            path=$(pwd)
        else
            path=$(realpath "$1" 2>/dev/null || echo "$1")
        fi
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo -n "$path" | pbcopy
        elif command -v xclip >/dev/null 2>&1; then
            echo -n "$path" | xclip -selection clipboard
        elif command -v wl-copy >/dev/null 2>&1; then
            echo -n "$path" | wl-copy
        else
            echo "Error: No clipboard tool found (pbcopy/xclip/wl-copy)"
            exit 1
        fi
        
        echo "Copied path to clipboard: $path"
      '';
      executable = true;
    };

    # Enhanced clipboard utilities
    "Scripts/clipwatch" = {
      text = ''
        #!/usr/bin/env bash
        # Watch clipboard contents and show changes
        
        echo "📋 Clipboard Watcher - Press Ctrl+C to stop"
        echo "=========================================="
        
        last_clip=""
        
        while true; do
            if [[ "$OSTYPE" == "darwin"* ]]; then
                current_clip=$(pbpaste 2>/dev/null)
            elif command -v xclip >/dev/null 2>&1; then
                current_clip=$(xclip -selection clipboard -o 2>/dev/null)
            elif command -v wl-paste >/dev/null 2>&1; then
                current_clip=$(wl-paste 2>/dev/null)
            else
                echo "Error: No clipboard tool found"
                exit 1
            fi
            
            if [[ "$current_clip" != "$last_clip" ]]; then
                echo "$(date '+%H:%M:%S') - Clipboard changed:"
                echo "==================="
                if [[ ''${#current_clip} -gt 100 ]]; then
                    echo "''${current_clip:0:100}..."
                else
                    echo "$current_clip"
                fi
                echo ""
                last_clip="$current_clip"
            fi
            
            sleep 1
        done
      '';
      executable = true;
    };
    
    "Scripts/clipclear" = {
      text = ''
        #!/usr/bin/env bash
        # Clear clipboard contents
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo -n "" | pbcopy
        elif command -v xclip >/dev/null 2>&1; then
            echo -n "" | xclip -selection clipboard
        elif command -v wl-copy >/dev/null 2>&1; then
            echo -n "" | wl-copy
        else
            echo "Error: No clipboard tool found"
            exit 1
        fi
        
        echo "🗑️  Clipboard cleared"
      '';
      executable = true;
    };
    
    "Scripts/clipshow" = {
      text = ''
        #!/usr/bin/env bash
        # Show clipboard contents with formatting
        
        echo "📋 Current Clipboard Contents:"
        echo "=============================="
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
            content=$(pbpaste 2>/dev/null)
        elif command -v xclip >/dev/null 2>&1; then
            content=$(xclip -selection clipboard -o 2>/dev/null)
        elif command -v wl-paste >/dev/null 2>&1; then
            content=$(wl-paste 2>/dev/null)
        else
            echo "Error: No clipboard tool found"
            exit 1
        fi
        
        if [[ -z "$content" ]]; then
            echo "(empty)"
        else
            echo "Length: ''${#content} characters"
            echo "Lines: $(echo "$content" | wc -l)"
            echo ""
            echo "Content:"
            echo "--------"
            echo "$content"
        fi
      '';
      executable = true;
    };

    # Network Utility Scripts
    "Scripts/myip" = {
      text = ''
        #!/usr/bin/env bash
        # Get public IP address
        
        echo -n "Public IP: "
        if command -v curl >/dev/null 2>&1; then
            curl -s --max-time 5 ifconfig.me || \
            curl -s --max-time 5 ipinfo.io/ip || \
            curl -s --max-time 5 checkip.amazonaws.com || \
            echo "Failed to get public IP"
        else
            echo "Error: curl is required"
            exit 1
        fi
      '';
      executable = true;
    };
    
    "Scripts/localip" = {
      text = ''
        #!/usr/bin/env bash
        # Get local IP address
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            echo -n "Local IP: "
            ipconfig getifaddr en0 2>/dev/null || \
            ipconfig getifaddr en1 2>/dev/null || \
            echo "No active network interface found"
        else
            # Linux
            echo -n "Local IP: "
            ip route get 1 2>/dev/null | awk '{print $7; exit}' || \
            hostname -I 2>/dev/null | awk '{print $1}' || \
            echo "No active network interface found"
        fi
      '';
      executable = true;
    };
    
    "Scripts/speedtest" = {
      text = ''
        #!/usr/bin/env bash
        # Run internet speed test
        
        echo "Running speed test..."
        echo ""
        
        if command -v speedtest-cli >/dev/null 2>&1; then
            speedtest-cli
        else
            echo "Installing speedtest-cli..."
            if command -v curl >/dev/null 2>&1; then
                curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3
            else
                echo "Error: curl and python3 are required"
                echo "Install speedtest-cli: pip install speedtest-cli"
                exit 1
            fi
        fi
      '';
      executable = true;
    };
    
    "Scripts/netinfo" = {
      text = ''
        #!/usr/bin/env bash
        # Show comprehensive network information
        
        echo "🌐 Network Information"
        echo "===================="
        echo ""
        
        # Local IP
        if [[ "$OSTYPE" == "darwin"* ]]; then
            local_ip=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)
        else
            local_ip=$(ip route get 1 2>/dev/null | awk '{print $7; exit}' || hostname -I 2>/dev/null | awk '{print $1}')
        fi
        
        if [[ -n "$local_ip" ]]; then
            echo "🏠 Local IP:  $local_ip"
        else
            echo "🏠 Local IP:  Not found"
        fi
        
        # Public IP
        echo -n "🌍 Public IP: "
        if command -v curl >/dev/null 2>&1; then
            public_ip=$(curl -s --max-time 3 ifconfig.me 2>/dev/null)
            if [[ -n "$public_ip" ]]; then
                echo "$public_ip"
            else
                echo "Unable to fetch"
            fi
        else
            echo "curl not available"
        fi
        
        # DNS servers
        if [[ "$OSTYPE" == "darwin"* ]]; then
            dns_servers=$(scutil --dns 2>/dev/null | grep nameserver | head -3 | awk '{print $3}' | tr '\n' ', ' | sed 's/,$//')
        else
            dns_servers=$(grep nameserver /etc/resolv.conf 2>/dev/null | awk '{print $2}' | tr '\n' ', ' | sed 's/,$//')
        fi
        
        if [[ -n "$dns_servers" ]]; then
            echo "🔍 DNS:       $dns_servers"
        fi
        
        echo ""
        echo "Run 'speedtest' for connection speed test"
      '';
      executable = true;
    };

    # Smart Nix Helper Scripts
    "Scripts/nixsearch" = {
      text = ''
        #!/usr/bin/env bash
        # Enhanced nix search with package preview
        
        if [[ $# -eq 0 ]]; then
            echo "Usage: nixsearch <package_name>"
            echo "Example: nixsearch firefox"
            exit 1
        fi
        
        package="$1"
        echo "🔍 Searching for: $package"
        echo ""
        
        # Search and format output
        nix search nixpkgs "$package" --json 2>/dev/null | \
        jq -r 'to_entries[] | "📦 \(.key)\n   \(.value.description // "No description")\n   Version: \(.value.version // "unknown")\n"' | \
        head -20
        
        if [[ $? -ne 0 ]]; then
            echo "Search failed. Trying basic search..."
            nix search nixpkgs "$package" | head -10
        fi
      '';
      executable = true;
    };
    
    "Scripts/nixinfo" = {
      text = ''
        #!/usr/bin/env bash
        # Show Nix system information
        
        echo "❄️  Nix System Information"
        echo "========================="
        echo ""
        
        # Nix version
        echo "📦 Nix version: $(nix --version 2>/dev/null || echo 'Not found')"
        
        # Current generation
        if [[ "$OSTYPE" == "darwin"* ]]; then
            current_gen=$(darwin-rebuild --list-generations 2>/dev/null | tail -1 | awk '{print $1}' || echo "unknown")
            echo "🔄 Current generation: $current_gen"
        else
            current_gen=$(nixos-rebuild list-generations 2>/dev/null | tail -1 | awk '{print $1}' || echo "unknown")  
            echo "🔄 Current generation: $current_gen"
        fi
        
        # Flake status
        if [[ -f ~/.dotfiles/flake.lock ]]; then
            last_update=$(date -r ~/.dotfiles/flake.lock "+%Y-%m-%d %H:%M" 2>/dev/null || echo "unknown")
            echo "🔒 Flake last updated: $last_update"
        fi
        
        # Store info
        if command -v nix >/dev/null 2>&1; then
            store_size=$(du -sh /nix/store 2>/dev/null | awk '{print $1}' || echo "unknown")
            echo "💾 Store size: $store_size"
        fi
        
        # Available commands
        echo ""
        echo "🛠️  Available commands:"
        echo "   nixswitch  - Apply configuration"
        echo "   nixup      - Update flake and apply"  
        echo "   nixtest    - Test configuration"
        echo "   nixclean   - Clean up old generations"
        echo "   nixgen     - List generations"
        echo "   nixsearch  - Search packages"
      '';
      executable = true;
    };
    
    "Scripts/nixvalidate" = {
      text = ''
        #!/usr/bin/env bash
        # Pre-flight checks before nixswitch
        
        echo "🔍 Validating Nix configuration..."
        echo ""
        
        # Check if in correct directory
        if [[ ! -f ~/.dotfiles/flake.nix ]]; then
            echo "❌ flake.nix not found in ~/.dotfiles"
            exit 1
        fi
        
        echo "✅ Found flake.nix"
        
        # Check syntax
        echo -n "🔧 Checking flake syntax... "
        if nix flake check ~/.dotfiles --no-build 2>/dev/null; then
            echo "✅ Syntax OK"
        else
            echo "❌ Syntax errors found"
            echo "Run 'nix flake check ~/.dotfiles' for details"
            exit 1
        fi
        
        # Check for common issues
        echo -n "🔍 Checking for common issues... "
        
        # Check for missing files
        if grep -r "source.*=" ~/.dotfiles/modules/ 2>/dev/null | grep -v ".nix:" | head -1 >/dev/null; then
            echo "⚠️  Found potential missing file references"
            grep -r "source.*=" ~/.dotfiles/modules/ | grep -v ".nix:" | head -3
        else
            echo "✅ No obvious issues"
        fi
        
        echo ""
        echo "🚀 Configuration looks good! Run 'nixswitch' to apply."
      '';
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
      
      # Smart Nix helpers
      nixtest = "nix flake check ~/.dotfiles";
      nixclean = "nix-collect-garbage -d && nix-store --optimize";
      nixgen = if pkgs.stdenv.isDarwin then "darwin-rebuild --list-generations" else "nixos-rebuild list-generations";
      
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
      nixswitch = "darwin-rebuild switch --flake ~/.dotfiles#Stefans-MacBook-Pro";
      nixup = "pushd ~/.dotfiles; nix flake update; nixswitch; popd";
    } else {
      # claude alias removed - using system claude binary
      nixbuild = "nix build ~/.dotfiles#nixosConfigurations.stefan.config.system.build.toplevel";
      nixcheck = "sudo nixos-rebuild dry-build --flake ~/.dotfiles#stefan";
      nixswitch = "sudo nixos-rebuild switch --flake ~/.dotfiles#stefan";
      nixup = "pushd ~/.dotfiles; nix flake update; nixswitch; popd";
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
      export PATH="$PATH:/home/stefan/.dotnet/tools:/Users/stefan/.dotnet/tools:$HOME/Scripts"
      
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
