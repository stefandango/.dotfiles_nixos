# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, unstable, home-manager, hyprland, nixvim, vars, ... }:
#{ lib, inputs, pkgs, unstable, home-manager, hyprland, nixvim, ... }:

let
system = "x86_64-linux";
terminal = pkgs.${vars.terminal};
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../modules/env.nix
      ../modules/greetd.nix
      ../modules/scripts.nix
      ../modules/waybar.nix
      ../modules/pyprland.nix
      ../modules/swaync.nix	
      ../modules/hyprland.nix
      ../modules/rofi.nix
      ../theme/theming.nix
      ../modules/git.nix
      ../modules/kitty.nix
      ../modules/zsh.nix
      #../modules/nvim.nix
      ../modules/apps.nix
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
	opengl = {
		enable = true;
		extraPackages = with pkgs; [
			#intel-media-driver
			#vaapiIntel
			#rocm-opencl-icd
			#rocm-opencl-runtime
			amdvlk
		];
		extraPackages32 = with pkgs; [
			driversi686Linux.amdvlk
		];
		driSupport = true;
		driSupport32Bit = true;
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
  # Makes build fail GLIBC...
  i18n = {
		#defaultLocale = "en_DK.uft8";
		#extraLocaleSettings = {
		#	LC_MESSAGES = "en_US.UFT-8";
		#	LC_TIME = "da_DK.UFT-8";
		#	LC_MONETARY = "da_DK.UTF-8";
		#};
		#supportedLocales = [ "en_US.UFT-8/UTF-8" "en_DK.UFT-8/UTF-8" "da_DK.UFT-8/UFT-8" ];
	};

   console = {
     font = "Lat2-Terminus16";
     keyMap = "dk";
  #   useXkbConfig = true; # use xkb.options in tty.
   };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  security = {
		rtkit.enable = true;
		polkit.enable = true;
		sudo.wheelNeedsPassword = false;
	};

 nixpkgs.config.allowUnfree = true;	
 #nixpkgs.config.allowUnfreePredicate = (pkg: true);
 fonts.packages = with pkgs;[
	 source-code-pro
		 corefonts
		 font-awesome
		 noto-fonts
		 noto-fonts-color-emoji
		 (nerdfonts.override {
		  fonts = [
		  "FiraCode" "JetBrainsMono"
		  ];
		  })
 ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget

  environment = {
  variables = {
		TERMINAL = "${vars.terminal}";
		EDITOR = "${vars.editor}";
		VISUAL = "${vars.editor}";
	};
  sessionVariables = {
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
		  kitty
		  neofetch
		  unzip
	          xdg-ninja
	
# VIDEO/AUDIO
		  alsa-utils
		  pavucontrol
		  pipewire
		  pulseaudio

# APPS
		  docker
		  lazydocker
		  jq
		  dotnet-sdk_8	
		  (python3.withPackages (ps: with ps; [
					 requests
					 openrazer
		  ]))
		  ] ++
		  (with unstable; [
#APPS
		   firefox
		  ]);
  };
  virtualisation.docker.enable = true;

  hardware.openrazer.enable = true; 
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
 
  services.flatpak.enable = true;          

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
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  #  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;


  home-manager.users.${vars.user} = {
    home.stateVersion = "23.11"; # <---- SETTING GOES HERE

   # xdg.enable = true;
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

