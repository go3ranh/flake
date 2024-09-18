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
    nginx = {
      enable = true;
      virtualHosts."${config.networking.fqdn}" = {
        enableACME = true;
        default = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://unix:${config.services.forgejo.settings.server.HTTP_ADDR}";
        };
      };
    };
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
          SSH_PORT = 22;
          START_SSH_SERVER = false;
        };
        log.LEVEL = "Warn";
      };
      package = pkgs.forgejo;
    };
  };
  networking = {
    hostName = "forgejo";
    useDHCP = false;
    # firewall.enable = lib.mkForce false;
    firewall.allowedTCPPorts = [ 22 80 443 9002 ];

    interfaces.ens18.ipv4.addresses = [{
      address = "10.0.0.21";
      prefixLength = 24;
    }];
    defaultGateway = "10.0.0.1";
    nftables = {
      # tables = {
      # 	filter = {
      # 		family = "inet";
      # 		enable = true;
      # 		content = ''
      #       chain input {
      #         type filter hook input priority 0;
      #         iifname lo accept
      #         ct state vmap { established : accept, related : accept, invalid : drop }

      #         ip saddr { 10.0.0.0/23, 10.200.0.0/24 } ip protocol icmp icmp type { destination-unreachable, router-advertisement, time-exceeded, parameter-problem, echo-request } counter accept
      #         ip saddr { 10.0.0.0/23, 10.200.0.0/24 } tcp dport { 22, 80, 443 } counter accept
      # 				drop
      #       }
      # 		'';
      # 	};
      # };
    };
  };
}
