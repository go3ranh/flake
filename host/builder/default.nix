{ config, pkgs, lib, ... }:

{
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  disko.devices = {
    disk = {
      sda = {
        device = "/dev/sda";
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

  nix = {
    sshServe = {
      enable = true;
      keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICt3IRfe/ysPl8jKMgYYlo2EEDnoyyQ/bY2u6qqMuWsQ goeranh@node5"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF+45vPiX86aXqAosIcy8KAYKOswkGbZyJadJR61YZ9Z root@node5"
      ];
      write = true;
    };

  };

  services = {
    nix-serve = {
      enable = true;
      openFirewall = true;
    };
  };

  systemd = {
    network = {
      enable = true;
      netdevs = { };
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
    services = { };
  };

  system.stateVersion = lib.mkForce "24.05";
}

