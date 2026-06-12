{ config, lib, pkgs, vars, inputs, ... }:

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
    # systemd-based initrd: required for plymouth to survive the simpledrm →
    # amdgpu DRM handover. Without this, plymouth renders to the EFI framebuffer,
    # then amdgpu seizes the display at ~4s and the splash goes invisible on the
    # ultrawide before the monitor re-syncs.
    initrd.systemd.enable = true;
    # Graphical boot splash — hides raw systemd/kernel output behind a clean
    # NixOS logo so transient early-boot messages don't flash on the TTY.
    plymouth = {
      enable = true;
      theme = "nixos-bgrt";
      themePackages = [ pkgs.nixos-bgrt-plymouth ];
    };
    kernelParams = [
      # NOTE: amdgpu.dcdebugmask=0x610 (disable PSR/PSR-SU/Panel Replay) was a
      # flicker workaround for the previous GPU. Removed after installing the
      # RX 9070 XT (Navi 48, DCN 4.0.1) — re-add if flickering reappears.
      "amdgpu.gpu_recovery=1"                           # Enable GPU reset on hang instead of crashing
      "quiet"                                           # Suppress kernel log output on console — needed for plymouth
      "splash"                                          # Tell plymouth to show the splash screen

      # Recolour the Linux VT's 16-colour palette to the One Dark Pro scheme
      # (theme/colors.nix). This is what makes the tuigreet login (a console
      # app limited to the 16 named ANSI colours) look themed instead of using
      # the garish default TTY palette. Order = palette slots 0..15
      # (0-7 normal, 8-15 bright): black, red, green, yellow, blue, magenta,
      # cyan, white, then the bright variants.
      "vt.default_red=0x11,0xe0,0x98,0xe5,0x61,0xc6,0x56,0xab,0x5c,0xe0,0x98,0xe5,0x61,0xc6,0x56,0xff"
      "vt.default_grn=0x11,0x6c,0xc3,0xc0,0xaf,0x78,0xb6,0xb2,0x63,0x6c,0xc3,0xc0,0xaf,0x78,0xb6,0xff"
      "vt.default_blu=0x11,0x75,0x79,0x7b,0xef,0xdd,0xc2,0xbf,0x70,0x75,0x79,0x7b,0xef,0xdd,0xc2,0xff"
    ];
    kernel.sysctl = {
      "vm.max_map_count" = 1048576;
      "vm.swappiness" = 10;
    };
  };

  # Hardware configuration
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    # Unlocks the voltage/frequency/power controls in the corectrl GUI by
    # setting amdgpu.ppfeaturemask=0xffffffff. Required to undervolt, tune
    # power limits, or set a custom fan curve. The actual values are set in
    # the corectrl app and re-applied automatically each boot.
    # (Renamed from programs.corectrl.gpuOverclock.enable.)
    amdgpu.overdrive.enable = true;
    # Disabled: openrazer 3.12.2 driver fails to build against kernel 7.0.x
    # (hid_report_raw_event signature changed to require 6 args). Re-enable
    # once nixpkgs ships a patched openrazer.
    # openrazer = {
    #   enable = true;
    #   batteryNotifier.enable = true;
    # };
    # Required for Bluetooth controller firmware (otherwise hci0 FW download
    # fails with -19 on boot). Also enables AMD microcode updates via the
    # default in hardware-configuration.nix.
    enableRedistributableFirmware = true;
  };

  # PulseAudio (disabled in favor of PipeWire)
  services.pulseaudio.enable = false;

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
  # earlySetup bundles the font into initrd so setfont doesn't fail on the
  # first vconsole-setup attempt before the store is fully available.
  # ter-v32n (Terminus 32px, the largest size) keeps the TTY — and the
  # tuigreet login screen, which renders on the console — legible on the
  # 5120x2160 display instead of microscopic 16px text.
  console = {
    packages = [ pkgs.terminus_font ];
    font = "ter-v32n";
    keyMap = "dk";
    earlySetup = true;
  };

  # Security
  security = {
    rtkit.enable = true;
    polkit.enable = true;
    sudo.wheelNeedsPassword = false;

    # Let local users reboot/power-off without a polkit password prompt.
    # The rofi power menu (Super+Shift+E) runs `systemctl reboot`/`poweroff`
    # from a process spawned by Hyprland. Hyprland (started by greetd) lives
    # in the root cgroup and is NOT tracked in any logind session
    # (`GetSessionByPID` => "does not belong to any known session"), so its
    # children appear to polkit as having NO session: subject.active and
    # subject.local are both false. reboot/power-off then fall back to
    # auth_admin (a challenge); with no polkit auth agent running the
    # challenge fails silently and nothing happens. (Lock/Logout work because
    # loginctl uses login1.manage, authorized by UID alone.)
    #
    # Gate on group membership only (UID-based, always resolvable) instead of
    # the unreachable subject.active/local. Safe here: single-user desktop
    # where wheel already has passwordless sudo, so `sudo reboot` is already
    # unrestricted.
    polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if ((action.id == "org.freedesktop.login1.reboot" ||
             action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
             action.id == "org.freedesktop.login1.power-off" ||
             action.id == "org.freedesktop.login1.power-off-multiple-sessions" ||
             action.id == "org.freedesktop.login1.halt" ||
             action.id == "org.freedesktop.login1.halt-multiple-sessions") &&
            subject.isInGroup("users")) {
          return polkit.Result.YES;
        }
      });
    '';
  };

  # Network drives
  fileSystems."/mnt/piserver" = {
    device = "//192.168.68.109/shared";
    fsType = "cifs";
    options = [
      "credentials=/etc/samba/credentials"
      "uid=1000"
      "gid=1000"
      "iocharset=utf8"
      "nofail"
      "_netdev"
      "x-systemd.automount"
      "x-systemd.idle-timeout=60"
      "x-systemd.device-timeout=5s"
      "x-systemd.mount-timeout=5s"
    ];
  };

  # NixOS-specific packages
  environment.systemPackages = with pkgs; [
    inputs.nix-claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default
    zsh  # Add zsh at system level
    # GUI Applications
    # firefox is now managed declaratively via modules/shared/firefox.nix (home-manager)
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    fastfetch
    
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
      # openrazer  # Disabled with hardware.openrazer (kernel 7.0.x build break)
    ]))
    
    # Network filesystems
    cifs-utils

    # Hardware tools
    lshw
    amdgpu_top   # AMD GPU TUI: usage, power draw, temps, VRAM, per-process
    nvtopPackages.amd   # htop-style GPU monitor with live graphs (AMD build)
    protontricks
    winetricks

    # Gaming
    lutris
    wineWow64Packages.staging
    mangohud
    corectrl
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
    liberation_ttf
    inter
  ];

  fonts.fontconfig = {
    antialias = true;
    hinting = {
      enable = true;
      style = "slight";
    };
    subpixel = {
      rgba = "rgb";
      lcdfilter = "default";
    };
    localConf = ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
      <fontconfig>
        <match target="pattern">
          <edit name="dpi" mode="assign">
            <double>120</double>
          </edit>
        </match>
      </fontconfig>
    '';
  };

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
    nix-ld.enable = true;
    zsh.enable = true;  # Enable zsh system-wide
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    steam = {
      enable = true;
      gamescopeSession.enable = true;
    };
    gamemode = {
      enable = true;
      settings = {
        general = {
          renice = 10;
        };
        gpu = {
          apply_gpu_optimisations = "accept-responsibility";
          gpu_device = 1;
        };
      };
    };
    corectrl = {
      enable = true;
      # GPU overclock/undervolt unlock moved to hardware.amdgpu.overdrive.enable
      # (the option was renamed away from programs.corectrl).
    };
  };

  # Steam package overrides
  nixpkgs.config.packageOverrides = pkgs: {
    steam = pkgs.steam.override {
      extraPkgs = pkgs: with pkgs; [
        pango
        libthai
        harfbuzz
        gamemode
        # MangoHud inside Steam's FHS env so the Vulkan implicit layer is
        # visible to Proton games running under pressure-vessel (the container
        # can't see nix-store layer paths otherwise). Needed for the overlay
        # to show up on Proton/Wine titles, not just native Linux games.
        mangohud
      ];
    };
  };

  # I/O scheduler: none for NVMe (lowest overhead).
  # Match only namespace block devices (nvme0n1) — controllers (nvme0) and
  # partitions (nvme0n1p1) have no queue/scheduler and trigger udev errors.
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="none"
  '';

  # Process priority optimization for gaming
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
  };

  # Docker
  virtualisation.docker.enable = true;

  # Linux-specific nix settings
  nix.settings = {
    auto-optimise-store = true;
    use-xdg-base-directories = true;
  };
  nix.gc.dates = "weekly";

  # User configuration
  users.users.${vars.user} = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "video" "audio" "networkmanager" "lp" "input" "docker" "corectrl" "gamemode" ];
  };
}
