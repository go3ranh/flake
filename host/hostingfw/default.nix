{ config, pkgs, lib, ... }:

{
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  fileSystems."/" =
    { device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };


	boot = {
		loader = {
			systemd-boot.enable = true;
			efi.canTouchEfiVariables = true;
		};
		initrd = {
		  availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
		  kernelModules = [ ];
		};
		kernelModules = [ ];
		extraModulePackages = [ ];
	};

  networking = {
    hostName = "nixfw";
    interfaces = {
      ens18.ipv4.addresses = [{
        address = "10.16.23.95";
        prefixLength = 21;
      }];
      ens19.ipv4.addresses = [{
        address = "10.0.0.1";
        prefixLength = 24;
      }];
    };
    defaultGateway = "10.16.23.1";
    nameservers = [ "1.1.1.1" ];
    nftables = {
      enable = true;
      ruleset = ''
          table ip nat {
            chain PREROUTING {
              type nat hook prerouting priority dstnat; policy accept;
            }
          }
      '';
    };
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
    nat = {
      enable = true;
      internalInterfaces = [ "ens19" ];
      externalInterface = "ens18";
      forwardPorts = [
      ];
    };
  };
  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "en_US.UTF-8";

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };
	goeranh = {
		server = true;
		trust-builder = false;
		remote-store = false;
	};

  services = {
  };

  system.stateVersion = "23.11";
}

