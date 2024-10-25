{ config, pkgs, lib, ... }:

{
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  fileSystems."/" =
    {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-label/boot";
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
    hostName = "build";
    useDHCP = lib.mkForce false;
		nftables.enable = true;
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

  systemd = {
    network = {
      enable = true;
      netdevs = {
      };
      networks = {
        ens18 = {
          matchConfig.Name = "ens18";
          address = [
            "10.1.1.148/21"
          ];
          DHCP = "no";
          gateway = [
            "10.1.1.1"
          ];
          networkConfig = {
            IPv6AcceptRA = true;
          };
        };
      };
    };
    services = {
    };
  };

  system.stateVersion = "24.05";
}

