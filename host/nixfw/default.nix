{ config, pkgs, lib, ... }:

{
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  fileSystems."/" =
    {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };


  boot = {
    loader = {
      systemd-boot.enable = true;
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
    hostName = "nixfw";
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
        wt0 = {
          allowedTCPPorts = [ 53 9002 ];
          allowedUDPPorts = [ 53 ];
        };
        ens19 = {
          allowedTCPPorts = [ 53 9002 ];
          allowedUDPPorts = [ 53 ];
        };
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

  services = {
    bind = {
      enable = true;
      zones = {
        "netbird.selfhosted" =
          let
            zonefile = pkgs.writeText "zone" ''
              $ORIGIN netbird.selfhosted.
              $TTL 3600
              netbird.selfhosted.  IN  SOA   nixfw.netbird.selfhosted. goeranh.netbird.selfhosted. ( 2020091025 7200 3600 1209600 3600 )
              netbird.selfhosted.  IN  NS    nixfw

              onlyoffice.kbuild  IN  CNAME kbuild
              kbuild             IN  A     100.87.25.209
              pitest             IN  A     100.87.123.127
              nixfw              IN  A     100.87.17.62
              dockerhost         IN  A     10.0.0.132
              git-website        IN  A     10.0.0.23
              monitoring         IN  A     10.0.0.26
              node5              IN  A     100.87.55.241
              server-gitea       IN  A     100.87.18.24
              workstation        IN  A     100.87.106.167
              oraclearm          IN  A     100.87.250.85
              					'';
          in
          {
            master = true;
            file = "${zonefile}";
          };
      };
      extraOptions = ''
        			recursion yes;
        			allow-recursion { any; };
        			'';
    };
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
                PublicKey = "fvGBgD6oOqtcgbbLXDRptL1QomkSlKh29I9EhYQx1iw=";
                AllowedIPs = [ "10.200.0.0/24" ];
                Endpoint = "49.13.134.146:51820";
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
            "10.200.0.5/24"
          ];
          DHCP = "no";
          networkConfig = {
            IPv6AcceptRA = false;
          };
        };
        ens18 = {
          matchConfig.Name = "ens18";
          address = [
            "10.16.23.95/21"
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
            "10.0.0.1/24"
          ];
          DHCP = "no";
          networkConfig = {
            IPv6AcceptRA = false;
          };
        };
      };
    };
  };

  system.stateVersion = "23.11";
}

