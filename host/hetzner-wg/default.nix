{ self, config, lib, pkgs, ... }: {
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
  goeranh = {
    server = true;
    update = true;
    monitoring = false;
  };

  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
    grub.enable = true;
  };

  users.users.goeranh.initialPassword = "testtest";

  services = {
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
      };
    };
  };
  networking = {
    hostName = "hetzner-wg";

    useDHCP = false;
    # allow wireguard port
    firewall.allowedUDPPorts = [ 51820 ];
    usePredictableInterfaceNames = false;
  };
  systemd = {
    services = {
      wireguard-setup = {
        enable = true;
        script = ''
          if [ ! -d /var/lib/wireguard ]; then
            mkdir /var/lib/wireguard
          fi
          if [ ! -f /var/lib/wireguard/private ]; then
            ${pkgs.wireguard-tools.outPath}/bin/wg genkey > /var/lib/wireguard/private
          fi
        '';
        wantedBy = [ "multiuser.target" ];
      };
    };
    network = {
      enable = true;
      netdevs = {
        "50-wg0" = {
          netdevConfig = {
            Kind = "wireguard";
            Name = "wg0";
            MTUBytes = "1300";
          };
          wireguardConfig = {
            PrivateKeyFile = "/var/lib/wireguard/private";
            ListenPort = 51820;
          };
          wireguardPeers = [
            {
              # node5
              wireguardPeerConfig = {
                PublicKey = "fyJDrrVSaU6ZBsYY19FPT++PPwX8Muyw9wkA+YxoET0=";
                AllowedIPs = [ "10.200.0.2" ];
              };
            }
            {
              # fedora vm
              wireguardPeerConfig = {
                PublicKey = "D0QJSN9zM1lxNsfrgYVA5DVyE6woz5U27kqQpQF13CQ=";
                AllowedIPs = [ "10.200.0.3" ];
              };
            }
            {
              # pitest
              wireguardPeerConfig = {
                PublicKey = "F4yaZ9zabNpQSpV+fXAvla6klsv6SppG3Ic3IMlAxnE=";
                AllowedIPs = [ "10.200.0.4" ];
              };
            }
            {
              # nixfw
              wireguardPeerConfig = {
                PublicKey = "gmCG/K+cVYNdz9R7raBcU+OpGF+lQ9ClCGhfbC3THmY=";
                AllowedIPs = [ "10.200.0.5" "10.0.0.0/24" "10.0.1.0/24" ];
              };
            }
          ];
        };
      };
      networks = {
        wg0 = {
          matchConfig.Name = "wg0";
          address = [ "10.200.0.1/24" ];
          networkConfig = {
            IPMasquerade = "ipv4";
            IPForward = true;
          };
          routes = [
					  {
							routeConfig = {
								Gateway = "10.200.0.5";
								Destination = "10.0.0.0/24";
							};
						}
					  {
							routeConfig = {
								Gateway = "10.200.0.5";
								Destination = "10.0.0.0/24";
							};
						}
						];
        };
        "eth0" = {
          matchConfig.Name = "eth0";
          address = [
            "2a01:4f8:c013:27a4::1"
          ];
          DHCP = "yes";
          networkConfig = {
            IPv6AcceptRA = false;
          };
        };
      };
    };
  };
}
