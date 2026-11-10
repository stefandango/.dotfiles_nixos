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
        FXPreferredViewStyle = "Nlsv";   # list view for new windows
        ShowPathbar = true;              # breadcrumb path bar
        ShowStatusBar = true;            # item count / free space
        _FXSortFoldersFirst = true;      # folders grouped above files
      };
      CustomUserPreferences = {
        "com.apple.desktopservices" = {
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;
        };
      };
      trackpad = {
        Clicking = true;
        TrackpadThreeFingerDrag = true;
      };
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        # Key repeat speed (lower = faster)
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
        # Disable auto-correct annoyances
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
      };
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
      screencapture = {
        # Absolute path so it works regardless of ~ expansion; dir is
        # created by home-manager (see home/default.nix) so macOS doesn't
        # silently fall back to the Desktop.
        location = "/Users/${vars.user}/Pictures/screenshots";
        type = "png";
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
    pom  # Terminal-based Pomodoro timer with notifications
    llama-cpp  # Metal acceleration auto-enabled on aarch64-darwin
    # herdr-core (`hc`), the backend the herdr-app cask needs: the cask does
    # not bundle it and Homebrew has no formula. The app looks for hc on PATH,
    # then in usual install places including /run/current-system/sw/bin, which
    # is where this lands -- so it is found even when launched from Finder.
    # NixOS needs nothing: nixpkgs' herdr-desktop hardcodes its own herdr-core.
    herdr-core
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
    # Uninstalls packages that are no longer in the generated Brewfile.
    # nix-darwin emits `--force-cleanup` for this; Homebrew 7.0.12 accepts that
    # flag and rejects `--cleanup` as disabled.
    onActivation.cleanup = "uninstall";
    onActivation.upgrade = true;
    onActivation.autoUpdate = true;
    caskArgs.appdir = "/Applications";
    # No caskArgs.no_quarantine: Homebrew 7 removed --no-quarantine, and the
    # Brewfile then fails every new cask with "invalid option". New apps get
    # Gatekeeper's one-time first-launch prompt instead.
    global.brewfile = true;
    masApps = { };
    casks = [
      "firefox"
      "raycast"
      "kitty"
      "devutils"
      "handbrake-app"
      "alt-tab"
      "dbeaver-community"
      "discord"
      "fork"
      "font-monaspice-nerd-font"
      "font-noto-sans-symbols-2"
      { name = "tailscale-app"; greedy = true; }
      # herdr's desktop app (NixOS: herdr-desktop in modules/nixos/apps.nix).
      # Cask rather than nixpkgs: it is newer than nixpkgs' herdr-desktop and
      # updates itself (auto_updates), so not greedy.
      "herdr-app"
    ];
    brews = [ "uv" "herdr" ];
  };

  # Touch ID for sudo (reattach makes it work inside tmux too)
  security.pam.services.sudo_local.touchIdAuth = true;
  security.pam.services.sudo_local.reattach = true;

  # User configuration
  users.users.${vars.user} = {
    name = vars.user;
    home = "/Users/${vars.user}";
    shell = pkgs.zsh;
  };
}
