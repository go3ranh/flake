{ config, pkgs, ... }:
{
  security = {
    sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };
  };
  networking = {
    hostName = "vaultwarden";
    firewall.allowedTCPPorts = [ 22 80 443 ];
    defaultGateway = "10.0.0.1";
    useDHCP = false;
  };

  systemd = {
    network = {
      enable = true;
      networks = {
        ens18 = {
          matchConfig.Name = "ens18";
          address = [
            "10.0.0.16/24"
          ];
          DHCP = "no";
          gateway = [
            "10.0.0.1"
          ];
          networkConfig = {
            IPv6AcceptRA = true;
          };
        };
      };
    };
  };

  services.openssh.enable = true;
  services = {
    vaultwarden = {
      enable = true;
      #backupDir = "/home/goeranh/ssd/vaultwarden/backup";
      config = {
        DOMAIN = "https://${config.networking.fqdn}/";
        SIGNUPS_ALLOWED = false;
        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = 8222;
        ROCKET_LOG = "critical";
      };
    };
    nginx = {
      enable = true;
      virtualHosts."${config.networking.fqdn}" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${config.services.vaultwarden.config.ROCKET_ADDRESS}:${builtins.toString config.services.vaultwarden.config.ROCKET_PORT}";
        };
      };
    };
  };
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
}
