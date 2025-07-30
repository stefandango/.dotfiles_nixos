{ config, lib, inputs, pkgs, unstable, home-manager, nixvim, darwin, vars, ... }:

let
    system = "aarch64-darwin";
    terminal = pkgs.${vars.terminal};
in
    {
    imports =
        [
            inputs.home-manager.darwinModules.home-manager
            ../../modules/shared
        ];
    users.users.stefan = {
        name = "stefan";
        home = "/Users/stefan";
    };
    programs.zsh.enable = true;
    environment = {
        shells = with pkgs; [ bash zsh ];
        systemPackages = with pkgs; [
            coreutils
            tmuxPlugins.onedark-theme
            tmuxPlugins.tokyo-night-tmux
            tmuxPlugins.better-mouse-mode
            tree
            powershell
            go
            rustup
            vlc-bin
        ];
        systemPath = [ "/opt/homebrew/bin" ];
        pathsToLink = [ "/Applications" ];
        variables.EDITOR = "nvim";
        
        };

    fonts.packages = [
        pkgs.nerd-fonts.jetbrains-mono
    ];

    system.primaryUser = "stefan";
    system.defaults = {
        finder = {
            _FXShowPosixPathInTitle = true;
            AppleShowAllExtensions = true;
        };
        trackpad = {
            Clicking = true;
            TrackpadThreeFingerDrag = true;
        };
        NSGlobalDomain.AppleShowAllExtensions = true;
        dock = {
            autohide = true;
            show-recents = false;
            launchanim = true;
            mouse-over-hilite-stack = true;
            orientation = "bottom";
            tilesize = 50;
            magnification = true;
            largesize = 80;
        };
    };
    homebrew = {
        enable = true;
        caskArgs.no_quarantine = true;
        global.brewfile = true;
        masApps = { };
        casks = [
            "raycast"
            "kitty"
            "pearcleaner"
            "devutils"
            "bartender"
            "handbrake"
            "alt-tab"
            "dbeaver-community"
            # Fonts for terminal (tmux tokyo-night)
            "font-monaspace-nerd-font"
            "font-noto-sans-symbols-2"
        ];
        # Kitty is double installed above to fix permission error on macOS
        brews = [ "python" "uv" ];
    };
    security.pam.services.sudo_local.touchIdAuth = true;
    system.stateVersion = 4;
    nixpkgs.hostPlatform = "aarch64-darwin";
    ids.gids.nixbld = 350;
    nix = {
        gc = {
            automatic = true;
            interval = { Weekday = 0; Hour = 2; Minute = 0; };
            options = "--delete-older-than 30d";
        };

        extraOptions = ''
          experimental-features = nix-command flakes
        '';
    };
}
