{ config, lib, inputs, pkgs, unstable, home-manager, nixvim, darwin, vars, ... }:

let
system = "x86_64-darwin";
terminal = pkgs.${vars.terminal};
in
{
    imports =
    [
      inputs.home-manager.darwinModules.home-manager
          ../../modules/shared
          #../../modules/git.nix
          #../../modules/kitty.nix
          #../../modules/zsh.nix
    ];
    users.users.stefan = {
      name = "stefan";
      home = "/Users/stefan";
    };
    programs.zsh.enable = true;
    environment = {
    shells = with pkgs; [ bash zsh ];
    #loginShell = pkgs.zsh;
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


  fonts.fontDir.enable = true; # DANGER
  fonts.fonts = [ (pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; }) ];
  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  #nix.package = pkgs.nix;
  # The platform the configuration will be used on.

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
        autohide = false;
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
      "CleanMyMac"
     ];
    #taps = [ "fujiapple852/trippy" ];
    #brews = [ "trippy" ];
  };
  security.pam.enableSudoTouchIdAuth = true;
  system.stateVersion = 4;
  nixpkgs.hostPlatform = "x86_64-darwin";

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
