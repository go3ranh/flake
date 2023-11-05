{ config, pkgs, lib, ... }: {
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];
  boot.loader.grub.device = "/dev/sda";

  networking = {
    useDHCP = true;
    hostName = "hetznertest";
    firewall.allowedTCPPorts = [ 22 ];
  };

  nixpkgs.hostPlatform = "x86_64-linux";

  goeranh = {
    server = true;
  };

  users.users.goeranh.password = "test";

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };
  disko.devices = {
    disk = {
      sda = {
        device = "/dev/sda";
        type = "disk";
        content = {
          type = "table";
          format = "msdos";
          partitions = [
            {
              name = "root";
              part-type = "primary";
              start = "1M";
              end = "100%";
              bootable = true;
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            }
          ];
        };
      };
    };
  };

  system.stateVersion = "23.05"; # Did you read the comment?
}
