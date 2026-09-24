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
        # /boot is 511M and each generation costs ~84M there (14M kernel + a 70M
        # initrd, fat because initrd.kernelModules pulls in amdgpu firmware). The
        # default limit of 100 filled the partition until switches died with
        # "No space left on device" — install-grub copies the new generation in
        # before pruning old ones, so the ceiling is (N+1) * 84M + 15M <= 511M.
        configurationLimit = 4;
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
      #
      # DP 2.1 UHBR — 2026-09-07 black-screen incident. The LG 45GX950A is set to
      # *DP 1.4* in its own OSD menu (Settings > General > DisplayPort Version),
      # NOT DP 2.1. That setting lives in the monitor, not here, so this note is
      # the only record of it. Leave it on 1.4 unless the cable is replaced first.
      #
      # What happened: the UHBR link degraded over ~2 days (isolated link losses
      # on 09-06, total failure on 09-07) until the panel stopped answering
      # DPCD/EDID entirely and every boot came up to a black screen. The GPU was
      # never the problem — no hang, no reset, no MCE/EDAC/AER; greetd started
      # and PAM opened the session every time, just with nothing on screen.
      # All errors were in dcn31_hpo_dp_link_enc_*, the HPO encoder amdgpu uses
      # *only* for DP 2.x UHBR (128b/132b) rates, which is why dropping to DP 1.4
      # cleared it outright: HBR3 goes through a different encoder entirely.
      #
      # Diagnosing a repeat: `journalctl -b -1 -k | grep -i 'hpo_dp_link_enc\|EDID err\|enabling link'`
      # and `sudo cat /sys/kernel/debug/dri/1/DP-*/link_settings` — the second
      # field is the link rate, 0x1e = HBR3 (8.1 Gbps/lane, DP 1.4's max).
      #
      # Cost of staying on 1.4 is ~nil: HBR3 + DSC still drives 5120x2160@165,
      # and the mode is capped to @120 for OLED gamma anyway (see hyprland.nix).
      # To go back to DP 2.1/165Hz, replace the cable with a VESA-certified DP80
      # (passive, <=2m) FIRST — cables sold as "DP 1.4 8K" routinely pass HBR3
      # forever and fail UHBR, which is exactly the pattern seen here.
      "amdgpu.gpu_recovery=1"                           # Enable GPU reset on hang instead of crashing
      "quiet"                                           # Suppress kernel log output on console — needed for plymouth
      "splash"                                          # Tell plymouth to show the splash screen

      # Recolour the Linux VT's 16-colour palette to the One Dark Pro scheme.
      # This is what makes the tuigreet login (a console
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
    # CoreCtrl removed 2026-09-11 (unused). With it went hardware.amdgpu.overdrive
    # .enable: that set amdgpu.ppfeaturemask=0xfffd7fff and had the driver upload
    # an overdrive table, the trigger in freedesktop drm/amd #5404 for a Navi48
    # SMU lockup. Back to stock power management. Re-add overdrive.enable + a
    # CoreCtrl profile if undervolt/power-cap control is wanted again.
    # DDC/CI to the monitor over the DisplayPort i2c bus, for ddcutil. Loads
    # i2c-dev and grants access to the "i2c" group (and to any locally seated
    # user). Lets brightness/volume/input be driven from the CLI instead of the
    # monitor's joystick -- see the ddcutil note in modules/nixos/apps.nix.
    i2c.enable = true;
    openrazer = {
      enable = true;
      batteryNotifier.enable = true;
      users = [ vars.user ];
    };
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
    # TEMP[mcp-nixos-fastmcp]: build mcp-nixos ourselves instead of its flake package
    # TEMP-CHECK: nix_input_missing mcp-nixos fastmcp3
    # Build mcp-nixos against our own nixpkgs (native fastmcp 3.3.1) instead of
    # inputs.mcp-nixos.packages.default, which force-pins fastmcp to 3.2.4 via its
    # `fastmcp3` overlay. That pin now breaks: nixos-unstable split fastmcp into
    # fastmcp + fastmcp-slim (3.3.1, monorepo `fastmcp_slim/` subdir), and the
    # 3.2.4 src has no such subdir → "chmod: cannot access 'source/fastmcp_slim'".
    # mkMcpNixos + pythonRelaxDeps builds cleanly on native fastmcp (needs >=3.2.0).
    # Revert to packages.default once upstream drops the fastmcp3 overlay.
    (inputs.mcp-nixos.lib.mkMcpNixos { inherit pkgs; })  # MCP server (used by .mcp.json)
    # herdr (agent multiplexer) from nixpkgs, not the upstream flake: nixpkgs
    # carries 0.9.1, and the plugin API our review-tab plugin needs
    # (modules/shared/herdr.nix) only exists from 0.7.0 on — the old
    # github:ogulcancelik/herdr/v0.6.6 input predates it entirely.
    herdr
    zsh  # Add zsh at system level
    # GUI Applications
    # firefox is now managed declaratively via modules/shared/firefox.nix (home-manager)
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    fastfetch
    
    # Audio/Video tools
    alsa-utils
    pavucontrol
    
    # Development
    # docker CLI is provided by virtualisation.docker.enable; docker-compose is
    # NOT (the module has no compose option), so it stays here.
    docker-compose
    lazydocker
    omnisharp-roslyn
    netcoredbg
    
    # Python with packages
    (python3.withPackages (ps: with ps; [
      requests
      openrazer
    ]))
    
    # Network filesystems
    cifs-utils

    # Hardware tools
    lshw
    # DDC/CI monitor control (needs hardware.i2c.enable above). The LG answers
    # on /dev/i2c-9 (card1-DP-3): brightness x10, contrast x12, volume x62,
    # input x60. Dual Mode is NOT reachable this way -- it is not exposed on any
    # VCP register, so it stays a bezel-button affair. Do not go poking the
    # xE0-xFF manufacturer range looking for it: that is the pattern implicated
    # in ddcutil issue #419, where an LG panel stopped waking from sleep.
    # The bus/connector pair is not stable across cable moves -- it was
    # i2c-8/card1-DP-2 until the 2026-09-07 DP port swap. Nothing here hardcodes
    # it, so just re-check with `ddcutil detect` if a script ever needs the path.
    ddcutil
    amdgpu_top   # AMD GPU TUI: usage, power draw, temps, VRAM, per-process
    nvtopPackages.amd   # htop-style GPU monitor with live graphs (AMD build)
    # protontricks now provided by programs.steam.protontricks.enable (wrapped for the FHS env)

    # Gaming. Steam brings its own Proton/SteamLinuxRuntime; wine and winetricks
    # are back for Anarchy Online (Project Rubi-Ka), which runs outside Steam via
    # ~/Scripts/ao-launch.sh -- raw `wine`, one WINEPREFIX per multibox instance
    # under ~/Games. Lutris is deliberately not restored with them: the launcher
    # always called wine directly, and lutris's 32-bit FHS env is what used to
    # drag in the i686 openldap that the TEMP[openldap-nocheck] overlay in
    # flake.nix exists to work around.
    wineWow64Packages.staging
    winetricks
    mangohud
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
    # Grayscale antialiasing (NOT subpixel/LCD). The LG 45GX950A is a WOLED
    # panel with a WRGB subpixel layout, so "rgb" subpixel rendering paints
    # onto the wrong physical subpixels and leaves colored fringing on glyph
    # edges — reads as fuzzy/"pixelated" text, worst in XWayland apps (rofi).
    # "none" = grayscale AA, no fringing; lcdfilter is then ignored.
    subpixel = {
      rgba = "none";
      lcdfilter = "none";
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

  # No `qt` block here on purpose. Qt follows GTK3 via home-manager's
  # qt.platformTheme.name = "gtk3" (theme/theming.nix), which puts
  # QT_QPA_PLATFORMTHEME=gtk3 in environment.d — and GTK3 is adw-gtk3-dark
  # carrying matugen's colours, so Qt inherits the wallpaper palette for free.
  #
  # This used to set platformTheme = "gnome" + style = "adwaita-dark". Both had
  # to go: home-manager's gtk3 already won the platformTheme race, and
  # style = "adwaita-dark" exported QT_STYLE_OVERRIDE, which makes adwaita-qt
  # paint its own fixed palette and ignore the platform theme entirely. That
  # override was the actual thing pinning Qt apps to a static dark grey.
  #
  # qt5ct/qt6ct are deliberately not used: neither is installed, and inheriting
  # GTK3 needs no colour files of its own.

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
      # Extra libraries + tools injected into Steam's FHS env (replaces the old
      # nixpkgs.config.packageOverrides steam.override { extraPkgs = ...; }).
      # MangoHud must live here so its Vulkan implicit layer is visible to
      # Proton games running under pressure-vessel (the container can't see
      # nix-store layer paths otherwise) — needed for the overlay on Proton/Wine
      # titles, not just native Linux games.
      extraPackages = with pkgs; [
        pango
        libthai
        harfbuzz
        gamemode
        mangohud
      ];
      # Properly wrapped protontricks for Steam's FHS env (was in systemPackages).
      protontricks.enable = true;
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
    rulesProvider = pkgs.ananicy-cpp;
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
    extraGroups = [ "wheel" "video" "audio" "networkmanager" "lp" "input" "docker" "gamemode" "i2c" ];
  };
}
