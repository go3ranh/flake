{ config, pkgs, lib, ... }:

{
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/832ec016-7d26-4a86-813b-ec375f698262";
      fsType = "ext4";
    };

  swapDevices = [ ];

  networking = {
    useDHCP = true;
    hostName = "kbuild";
    firewall.allowedTCPPorts = [ 22 ];
  };

  nixpkgs.hostPlatform = "x86_64-linux";

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  goeranh = {
    server = true;
    development = true;
    remote-store = true;
    update = true;
  };
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  services = {
    nginx = {
      enable = true;
      virtualHosts = {
        "${config.networking.fqdn}" = {
          sslCertificate = "/var/lib/${config.networking.fqdn}.crt";
          sslCertificateKey = "/var/lib/${config.networking.fqdn}.key";
          forceSSL = true;
          locations = {
            "/" = {
              proxyPass = "http://localhost:8081";
            };
            "/hydra/" = {
              proxyPass = "http://localhost:3000";
              #extraConfig = ''
              #  rewrite ^/git(.*)$ $1 break;
              #'';
            };
          };
        };
      };
    };
    hydra = {
      enable = true;
      hydraURL = "https://${config.networking.fqdn}/hydra";
      notificationSender = "hydra@kbuild.local";
    };
  };


  system.stateVersion = "23.05"; # Did you read the comment?

}
