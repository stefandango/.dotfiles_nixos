# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, inputs, pkgs, home-manager, nixvim, vars, ... }:

let
system = "x86_64-linux";
terminal = pkgs.${vars.terminal};
in
{
  imports =
    [ # Include the results of the hardware scan.
      inputs.home-manager.nixosModules.home-manager
      ./hardware-configuration.nix
      ../../modules/shared
      ../../modules/nixos
    ];


  users.users.${vars.user} = {
		isNormalUser = true;
		extraGroups = [ "wheel" "video" "audio" "networkmanager" "lp" "input" "openrazer" "docker" ];
 	};

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

  hardware = {
	graphics = {
		enable = true;
		extraPackages = with pkgs; [
			amdvlk
		];
		extraPackages32 = with pkgs; [
			driversi686Linux.amdvlk
		];
	};
  };
  networking.hostName = "nixos"; # Define your hostname.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "Europe/Copenhagen";
  time.hardwareClockInLocalTime = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

   console = {
     font = "Lat2-Terminus16";
     keyMap = "dk";
   };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  security = {
		rtkit.enable = true;
		polkit.enable = true;
		sudo.wheelNeedsPassword = false;
	};

 nixpkgs.config.allowUnfree = true;

 fonts = {
	packages = with pkgs; [
		source-code-pro
		corefonts
		font-awesome
		noto-fonts
		noto-fonts-color-emoji
		noto-fonts-cjk-sans
		nerd-fonts.fira-code
		nerd-fonts.jetbrains-mono
		inter
		roboto
		liberation_ttf
	];

	fontconfig = {
		enable = true;
		antialias = true;
		hinting = {
			enable = true;
			style = "slight";
		};
		subpixel = {
			rgba = "rgb";
			lcdfilter = "default";
		};
		defaultFonts = {
			serif = [ "Noto Serif" "Liberation Serif" ];
			sansSerif = [ "Inter" "Noto Sans" "Liberation Sans" ];
			monospace = [ "JetBrainsMono Nerd Font" "Source Code Pro" "Liberation Mono" ];
			emoji = [ "Noto Color Emoji" ];
		};
	};
 };

  # List packages installed in system profile. To search, run:
  # $ nix search wget

  environment = {
  variables = {
		TERMINAL = "${vars.terminal}";
		EDITOR = "${vars.editor}";
		VISUAL = "${vars.editor}";
	};

  systemPackages = with pkgs; [
# TERMINAL
	  terminal
		  btop
		  coreutils
		  killall
		  lshw
		  nix-tree
		  xdg-utils
		  vim
		  wget
		  git
		  neofetch
		  unzip
          zip
          gnupg
          pinentry
	      xdg-ninja
          tree
          cmatrix
          protontricks
          winetricks

# VIDEO/AUDIO
		  alsa-utils
		  pavucontrol

# APPS
		  docker
          docker-compose
		  lazydocker
		  jq
          omnisharp-roslyn
          netcoredbg
          nodejs_22
          firefox
          warp-terminal
		  (python3.withPackages (ps: with ps; [
					 requests
					 openrazer
		  ]))
		  ];
  };
  virtualisation.docker.enable = true;

  hardware.openrazer = {
    enable = true;
    batteryNotifier.enable = true;
  };
  hardware.pulseaudio.enable = false;
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


  nix = {
		settings = {
			experimental-features = "nix-command flakes";
			auto-optimise-store = true;
		};
		gc = {
			automatic = true;
			dates = "weekly";
			options = "--delete-older-than 2d";
		};
	};

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
   programs.gnupg.agent = {
     enable = true;
     enableSSHSupport = true;
   };
    programs.steam.enable = true;
    programs.steam.gamescopeSession.enable = true;

    nixpkgs.config.packageOverrides = pkgs: {
    steam = pkgs.steam.override {
      extraPkgs = pkgs: with pkgs; [
        pango
        libthai
        harfbuzz
      ];
    };
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  #  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  home-manager = {
		extraSpecialArgs = { inherit inputs;  };
		users = {
			stefan = import ../../nix;
		};
	};



  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "23.11"; # Did you read the comment?

}

