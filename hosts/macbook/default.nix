{ config, lib, pkgs, vars, ... }:

{
  # macOS-specific system configuration
  system = {
    stateVersion = 4;
    primaryUser = vars.user;
    
    defaults = {
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
  };

  # macOS-specific settings
  nixpkgs.hostPlatform = "aarch64-darwin";
  ids.gids.nixbld = 350;
  
  # Enable shell integration
  programs.zsh.enable = true;
  environment.shells = with pkgs; [ bash zsh ];
  environment.systemPath = [ "/opt/homebrew/bin" ];
  environment.pathsToLink = [ "/Applications" ];

  # macOS-specific packages
  environment.systemPackages = with pkgs; [
    powershell
    vlc-bin
  ];

  # Font management
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  # Darwin-specific nix settings  
  nix.optimise.automatic = true;
  nix.gc.interval = { Weekday = 0; Hour = 2; Minute = 0; };

  # Homebrew integration
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
      "font-monaspace-nerd-font"
      "font-noto-sans-symbols-2"
    ];
    brews = [ "python" "uv" ];
  };

  # Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  # User configuration
  users.users.${vars.user} = {
    name = vars.user;
    home = "/Users/${vars.user}";
    shell = pkgs.zsh;
  };
}
