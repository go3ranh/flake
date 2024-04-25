{ self, config, lib, pkgs, ... }: {
  disko.devices = {
    disk = {
      sda = {
        device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "500M";
              name = "ESP";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              name = "nixos";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
  goeranh = {
    server = true;
    update = true;
  };
  fileSystems = {
    "/".device = lib.mkForce "/dev/sda2";
    "/boot".device = lib.mkForce "/dev/sda1";
  };

  services = {
    openssh.enable = true;
    # gitlab = {
    # 	enable = true;
    # };
  };
  networking = {
    hostName = "gitlab";

    interfaces.ens18.ipv4.addresses = [{
      address = "10.0.0.21";
      prefixLength = 24;
    }];
    defaultGateway = "10.0.0.1";
  };
}
