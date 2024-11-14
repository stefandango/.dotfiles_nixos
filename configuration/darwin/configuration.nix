{ config, lib, inputs, pkgs, unstable, home-manager, nixvim, darwin, vars, ... }:

let
    #system = "x86_64-darwin";
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
            tmuxPlugins.better-mouse-mode
            tree
        ] ++
            (with unstable; [
                dotnet-sdk_8
            ]);
        systemPath = [ "/opt/homebrew/bin" ];
        pathsToLink = [ "/Applications" ];
    };

    fonts.packages = [ (pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; }) ];
    services.nix-daemon.enable = true;

    system.defaults = {
        finder = {
            _FXShowPosixPathInTitle = true;
            AppleShowAllExtensions = true;
        };
        trackpad = {
            Clicking = true;
            TrackpadThreeFingerDrag = true;
        };
        #dock.autohide = true;
        NSGlobalDomain.AppleShowAllExtensions = true;
        #NSGlobalDomain.InitialKeyRepeat = 14;
        #NSGlobalDomain.KeyRepeat = 1;
        dock = {
            autohide = true;
            show-recents = false;
            launchanim = true;
            mouse-over-hilite-stack = true;
            orientation = "bottom";
            tilesize = 48;
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
            "hiddenbar"
        ];
        #taps = [ "fujiapple852/trippy" ];
        #brews = [ "trippy" ];
    };
    security.pam.enableSudoTouchIdAuth = true;
    system.stateVersion = 4;
    #nixpkgs.hostPlatform = "x86_64-darwin";
    nixpkgs.hostPlatform = "aarch64-darwin";

    nix = {
        gc = {
            user = "root";
            automatic = true;
            interval = { Weekday = 0; Hour = 2; Minute = 0; };
            options = "--delete-older-than 30d";
        };

        extraOptions = ''
          experimental-features = nix-command flakes
        '';
    };
}
