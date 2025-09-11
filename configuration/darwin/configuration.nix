{ config, lib, inputs, pkgs, home-manager, nixvim, darwin, vars, ... }:

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
            direnv
            nix-direnv
        ];
        systemPath = [ "/opt/homebrew/bin" ];
        pathsToLink = [ "/Applications" ];
        variables.EDITOR = "nvim";
        
        };

    fonts.packages = with pkgs; [
        nerd-fonts.jetbrains-mono
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
            "linqpad"
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
        settings = {
            experimental-features = ["nix-command" "flakes"];
            substituters = [
                "https://cache.nixos.org/"
                "https://nix-community.cachix.org"
            ];
            trusted-public-keys = [
                "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            ];
        };
        optimise = {
            automatic = true;
        };
        gc = {
            automatic = true;
            interval = { Weekday = 0; Hour = 2; Minute = 0; };
            options = "--delete-older-than 30d";
        };
    };
}
