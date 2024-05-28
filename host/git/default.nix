{ config, pkgs, ... }:
{
  security = {
    sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };
  };
  networking = {
    hostName = "git";
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
            "10.0.0.17/24"
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
    forgejo = {
      enable = true;
      settings = {
        service.DISABLE_REGISTRATION = true;
        server = {
          ROOT_URL = "https://${config.networking.fqdn}/";
					PROTOCOL = "http+unix";
          WORK_PATH = "/var/lib/forgejo";
          DISABLE_SSH = false;
          DOMAIN = "${config.networking.fqdn}";
          SSH_DOMAIN = "${config.networking.fqdn}";
          SSH_PORT = 2222;
          START_SSH_SERVER = true;
        };
        log.LEVEL = "Warn";
      };
      package = pkgs.forgejo;
    };
    nginx = {
      enable = true;
      virtualHosts."${config.networking.fqdn}" = {
				enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "unix:${config.services.forgejo.settings.server.HTTP_ADDR}";
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
