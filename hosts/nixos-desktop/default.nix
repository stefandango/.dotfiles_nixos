{ config, lib, pkgs, vars, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # NixOS-specific system configuration  
  system.stateVersion = "23.11";
  
  # Boot configuration
  boot = {
    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      grub = {
        devices = [ "nodev" ];
        efiSupport = true;
        enable = true;
        useOSProber = true;
      };
    };
    kernelPackages = pkgs.linuxPackages_latest;
    initrd.kernelModules = [ "amdgpu" ];
  };

  # Hardware configuration
  hardware = {
    graphics = {
      enable = true;
      extraPackages = with pkgs; [ amdvlk ];
      extraPackages32 = with pkgs; [ driversi686Linux.amdvlk ];
    };
    openrazer = {
      enable = true;
      batteryNotifier.enable = true;
    };
    pulseaudio.enable = false;
  };

  # Networking
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
  };

  # Locale and time
  time.timeZone = "Europe/Copenhagen";
  time.hardwareClockInLocalTime = true;
  i18n.defaultLocale = "en_US.UTF-8";

  # Console configuration
  console = {
    font = "Lat2-Terminus16";
    keyMap = "dk";
  };

  # Security
  security = {
    rtkit.enable = true;
    polkit.enable = true;
    sudo.wheelNeedsPassword = false;
  };

  # NixOS-specific packages
  environment.systemPackages = with pkgs; [
    claude-code
    zsh  # Add zsh at system level
    # GUI Applications
    firefox
    neofetch
    
    # Audio/Video tools
    alsa-utils
    pavucontrol
    
    # Development
    docker
    docker-compose
    lazydocker
    omnisharp-roslyn
    netcoredbg
    
    # Python with packages
    (python3.withPackages (ps: with ps; [
      requests
      openrazer
    ]))
    
    # Hardware tools
    lshw
    protontricks
    winetricks
  ];

  # Font configuration
  fonts.packages = with pkgs; [
    source-code-pro
    corefonts
    font-awesome
    noto-fonts
    noto-fonts-color-emoji
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
  ];

  # Services
  services = {
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
      jack.enable = true;
    };
  };

  # Programs
  programs = {
    zsh.enable = true;  # Enable zsh system-wide
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    steam = {
      enable = true;
      gamescopeSession.enable = true;
    };
  };

  # Steam package overrides
  nixpkgs.config.packageOverrides = pkgs: {
    steam = pkgs.steam.override {
      extraPkgs = pkgs: with pkgs; [
        pango
        libthai
        harfbuzz
      ];
    };
  };

  # Docker
  virtualisation.docker.enable = true;

  # Linux-specific nix settings
  nix.settings.auto-optimise-store = true;
  nix.gc.dates = "weekly";

  # User configuration
  users.users.${vars.user} = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "video" "audio" "networkmanager" "lp" "input" "openrazer" "docker" ];
  };
}
