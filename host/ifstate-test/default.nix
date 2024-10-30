{ config, pkgs, lib, ... }:

{
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  disko.devices = {
    disk = {
      vda = {
        device = "/dev/vda";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02"; # for grub MBR
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

  boot = {
    loader.grub = {
      enable = true;
    };
    loader = {
      systemd-boot.enable = lib.mkForce false;
      efi.canTouchEfiVariables = true;
    };
    initrd = {
      availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
      kernelModules = [ ];
      network = {
        enable = true;

      };
    };
    kernelModules = [ ];
    extraModulePackages = [ ];
  };

  networking = {
    hostName = "build";
    useDHCP = lib.mkForce false;
    nftables.enable = true;
    ifstate = {
      initrd.enable = true;
      enable = true;
      settings = {
        interfaces = [{
          name = "enp1s0";
          addresses = [ "192.168.122.149/24" ];
          link = {
            state = "up";
            kind = "physical";
            #address = "2e:28:00:60:c2:1b";
          };
        }];
        routing.routes = [
          { to = "0.0.0.0/0"; via = "192.168.122.1"; }
        ];
      };
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

  services = { };

  system.stateVersion = lib.mkForce "24.05";
}

