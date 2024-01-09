{ config, pkgs, lib, ... }:

{
  boot = {
		binfmt.emulatedSystems = [ "aarch64-linux" ];
    kernelModules = [ ];
    extraModulePackages = [ ];
    initrd = {
      availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
      kernelModules = [ ];
    };
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/6d1f76d6-961b-44c7-98ff-d020ecbce7b4";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/D80A-1208";
      fsType = "vfat";
    };

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;

  networking.hostName = "workstation";
  time.timeZone = "Europe/Berlin";

  security.sudo.wheelNeedsPassword = false;
	goeranh = {
		server = true;
	};

  networking.firewall.allowedTCPPorts = [ 22 ];
  system.stateVersion = "23.11";

}

