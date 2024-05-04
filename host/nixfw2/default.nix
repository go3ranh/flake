{ config, pkgs, lib, ... }:

{
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

  networking = {
    hostName = "nixfw2";
		useDHCP = lib.mkForce false;
    nftables = {
      enable = true;
      ruleset = ''
        table ip nat {
          chain PREROUTING {
            type nat hook prerouting priority dstnat; policy accept;
          }
        }
      '';
    };
    firewall = {
      enable = true;
      interfaces = {
        # wt0 = {
        #   allowedTCPPorts = [ 53 9002 ];
        #   allowedUDPPorts = [ 53 ];
        # };
        # ens19 = {
        #   allowedTCPPorts = [ 53 9002 ];
        #   allowedUDPPorts = [ 53 ];
        # };
      };
      allowedTCPPorts = [ 22 ];
    };
    nat = {
      enable = true;
      internalInterfaces = [ "ens19" ];
      externalInterface = "ens18";
      forwardPorts = [
      ];
    };
  };

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
		openssh.enable = true;
  };

  systemd = {
    network = {
			enable = true;
      netdevs = {
        "10-wg0" = {
          netdevConfig = {
            Kind = "wireguard";
            Name = "wg0";
            MTUBytes = "1300";
          };
          wireguardConfig = {
            PrivateKeyFile = "/var/lib/wireguard/private";
            ListenPort = 9918;
          };
          wireguardPeers = [
						{
              wireguardPeerConfig = {
                PublicKey = "gmCG/K+cVYNdz9R7raBcU+OpGF+lQ9ClCGhfbC3THmY=";
                AllowedIPs = [ "10.220.0.0/24" "10.0.0.0/24" ];
                Endpoint = "10.16.23.95:51820";
								PersistentKeepalive = 30;
              };
						}
          ];
        };
      };
      networks = {
        wg0 = {
          matchConfig.Name = "wg0";
          address = [
            "10.220.0.2/24"
          ];
          DHCP = "no";
          networkConfig = {
            IPv6AcceptRA = false;
          };
					routes = [
					  {
							routeConfig = {
								Gateway = "10.220.0.1";
								Destination = "10.0.0.0/24";
							};
						}
					];
        };
        ens18 = {
          matchConfig.Name = "ens18";
          address = [
            "10.16.23.96/21"
          ];
          DHCP = "no";
          gateway = [
            "10.16.23.1"
          ];
          networkConfig = {
            IPv6AcceptRA = false;
          };
        };
        ens19 = {
          matchConfig.Name = "ens19";
          address = [
            "10.0.1.1/24"
          ];
          DHCP = "no";
					dns = [ "9.9.9.9" ];
          networkConfig = {
            IPv6AcceptRA = false;
          };
        };
      };
    };
  };

  system.stateVersion = "23.11";
}

