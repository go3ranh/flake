{ inputs, config, lib, pkgs, ... }:

{
	boot.plymouth = {
	  enable = true;
	};
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  systemd = {
    network = {
      enable = true;
		};
	};
  networking = {
		hostName = "node6";
    networkmanager.enable = true;
	};
  virtualisation.libvirtd.enable = true;
  programs.dconf.enable = true;

  programs.git.enable = true;

  sound.enable = true;
  hardware.pulseaudio.enable = false;
  services = {
    fwupd.enable = true;
    jack = {
      jackd.enable = true;
      alsa.enable = false;
      loopback = {
        enable = true;
      };
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = false;
    };
    gnome = {
      gnome-keyring.enable = true;
    };
    #printing.enable = true;
    #avahi.enable = true;
    #avahi.nssmdns = true;
    openssh.enable = lib.mkForce false;

  };

  # services.printing.enable = true;
	programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
  };

  goeranh = {
    desktop = true;
    development = true;
    monitoring = false;
  };

  environment.systemPackages = with pkgs; [
    neovim
    tmux
    wget

		hyprpaper
		kitty
		libnotify
		mako
		qt5.qtwayland
		qt6.qtwayland
		swayidle
		swaylock-effects
		wlogout
		wl-clipboard
		wofi
		waybar
  ];


  zramSwap = {
    enable = true;
	};

  system.stateVersion = "24.05"; # Did you read the comment?

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/30783b24-0831-4621-a16a-7a9daac30a12";
      fsType = "btrfs";
      options = [ "subvol=root"  "compress=zstd"];
    };

  fileSystems."/home" =
    { device = "/dev/disk/by-uuid/30783b24-0831-4621-a16a-7a9daac30a12";
      fsType = "btrfs";
      options = [ "subvol=home"  "compress=zstd"];
    };

  fileSystems."/var" =
    { device = "/dev/disk/by-uuid/30783b24-0831-4621-a16a-7a9daac30a12";
      fsType = "btrfs";
      options = [ "subvol=var"  "compress=zstd"];
    };

  fileSystems."/nix" =
    { device = "/dev/disk/by-uuid/30783b24-0831-4621-a16a-7a9daac30a12";
      fsType = "btrfs";
      options = [ "subvol=nix" "compress=zstd" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/12CE-A600";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp0s31f6.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp4s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
	hardware = {
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
    #enableAllFirmware = true;
  };
}
