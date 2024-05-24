{ config, pkgs, lib, ... }:
let
  cachePort = 8080;
in
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
    useDHCP = false;
    hostName = "kbuild";
    firewall.allowedTCPPorts = [ 22 80 443 ];
  };
  systemd = {
    network = {
			enable = true;
			config = {
				routeTables = {
					wg-blade = 10;
					wg-wg1 = 20;
				};
			};
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
                PublicKey = "fvGBgD6oOqtcgbbLXDRptL1QomkSlKh29I9EhYQx1iw=";
                AllowedIPs = [ "10.200.0.0/24" ];
                Endpoint = "49.13.134.146:1194";
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
            "10.200.0.9/24"
          ];
          DHCP = "no";
          networkConfig = {
            IPv6AcceptRA = false;
            IPForward = true;
          };
        };
        ens18 = {
          matchConfig.Name = "ens18";
          DHCP = "yes";
          gateway = [
            "10.16.23.1"
          ];
          networkConfig = {
            IPv6AcceptRA = false;
          };
        };
			};
		};
	};

  nixpkgs.hostPlatform = "x86_64-linux";

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  sops = {
    # This will automatically import SSH keys as age keys
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = ./secrets.yaml;
    defaultSopsFormat = "yaml";
    secrets = {
      "privateCacheKey" = {
        owner = "root";
        #group = "root";
        mode = "0400";
      };
    };
  };

  nix.settings.secret-key-files = [ "${config.sops.secrets.privateCacheKey.path}" ];

  goeranh = {
    server = true;
    development = true;
    remote-store = true;
  };
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  services = {
  };


  environment.systemPackages = with pkgs; [ borgbackup ];
  system.stateVersion = "23.11"; # Did you read the comment?

}
