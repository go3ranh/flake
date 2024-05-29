{ config, pkgs, ... }:
{
  security = {
    sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };
  };
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  networking = {
    hostName = "hydra";
    firewall.allowedTCPPorts = [ 22 80 443 ];
    defaultGateway = "10.0.0.1";
    useDHCP = false;
    hostId = "e679682b";
  };

  systemd = {
    network = {
      enable = true;
      networks = {
        ens18 = {
          matchConfig.Name = "ens18";
          address = [
            "10.0.0.30/24"
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
    nix-serve = {
      # enable = true;
      # secretKeyFile = "/var/cache-priv-key.pem";
    };
    hydra = {
      enable = true;
      useSubstitutes = true;
      notificationSender = "notify@hydra.goeranh.selfhosted";
      minimumDiskFree = 5;
      minimumDiskFreeEvaluator = 10;
      listenHost = "*";
      hydraURL = "https://${config.networking.fqdn}";
    };
    nginx = {
      enable = true;
      virtualHosts."${config.networking.fqdn}" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:3000/";
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
      };
    };
  };
  disko.devices = {
    disk = {
      sda = {
        device = "/dev/sda";
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
