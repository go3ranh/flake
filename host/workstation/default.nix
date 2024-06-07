{ config, pkgs, lib, ... }:

{
  boot = {
    binfmt.emulatedSystems = [ "aarch64-linux" ];
    kernelModules = [ ];
    extraModulePackages = [ ];
    initrd = {
      availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
      kernelModules = [ ];
    };
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/6d1f76d6-961b-44c7-98ff-d020ecbce7b4";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/D80A-1208";
      fsType = "vfat";
    };
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      trusted-public-keys = [
        "nixbsd:gwcQlsUONBLrrGCOdEboIAeFq9eLaDqfhfXmHZs1mgc="
      ];
      trusted-substituters = [
        "https://attic.mildlyfunctional.gay/nixbsd"
      ];
    };
  };

  swapDevices = [ ];

  networking = {
    useDHCP = lib.mkForce false;
    hostName = "workstation";
    nftables = {
      enable = true;
      ruleset = ''
        			  table inet filter {
        					chain input {
        						type filter hook input priority 0;
        						iifname lo accept
        						ct state {established, related} accept

        						ip saddr { 10.200.0.0/24, 10.0.0.0/24 } ip protocol { tcp, udp, icmp } counter accept

        						counter drop
        					}

        					chain output {
        						type filter hook output priority 0;
        						accept
        					}

        					chain forward {
        						type filter hook forward priority 0;
        						ct state {established, related} accept
        						counter drop
        					}
        				}
        			'';
    };
  };

  time.timeZone = "Europe/Berlin";

  virtualisation.libvirtd.enable = true;
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICt3IRfe/ysPl8jKMgYYlo2EEDnoyyQ/bY2u6qqMuWsQ goeranh@node5"
  ];

  security.sudo.wheelNeedsPassword = false;
  goeranh = {
    server = true;
    update = true;
  };

  services = {
    openssh.settings.X11Forwarding = true;
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
              PublicKey = "fvGBgD6oOqtcgbbLXDRptL1QomkSlKh29I9EhYQx1iw=";
              AllowedIPs = [ "fd4:10c9:3065:56db::2" "10.200.0.0/24" "10.0.0.0/24" "10.0.1.0/24" "10.16.17.0/21" ];
              Endpoint = "49.13.134.146:1194";
              PersistentKeepalive = 30;
            }
          ];
        };
      };
      networks = {
        wg0 = {
          matchConfig.Name = "wg0";
          address = [
            "10.200.0.3/24"
            "fd4:10c9:3065:56db::4/64"
          ];
          DHCP = "no";
          routes = [
            {
              Gateway = "10.200.0.5";
              Destination = "10.0.0.0/24";
            }
            {
              Gateway = "10.200.0.5";
              Destination = "10.0.1.0/24";
            }
          ];
          networkConfig = {
            IPv6AcceptRA = false;
          };
        };
        "ens18" = {
          matchConfig.Name = "ens18";
          address = [
            "10.16.17.42/21"
          ];
          DHCP = "no";
          gateway = [ "10.16.23.1" ];
          networkConfig = {
            IPv6AcceptRA = false;
          };
        };
      };
    };
  };
  system.stateVersion = "23.11";
}

