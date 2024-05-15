{ inputs, config, pkgs, lib, ... }:
let
  website = pkgs.stdenv.mkDerivation {
    pname = "website";
    version = "0.1";
    src = ./html;
    installPhase = ''
      			cp -r $src $out
      		'';
  };
in
{
  hardware.enableRedistributableFirmware = true;
  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";

  nixpkgs.config.packageOverrides = pkgs: {
    makeModulesClosure = x:
      # prevent kernel install fail due to missing modules
      pkgs.makeModulesClosure (x // { allowMissing = true; });
  };

  zramSwap = {
    enable = true;
  };
  boot = {
    # repeat https://github.com/NixOS/nixos-hardware/blob/master/raspberry-pi/4/default.nix#L20
    # to overwrite audio module
    kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;

    kernelParams = lib.mkForce [
      "snd_bcm2835.enable_headphones=1"
      # don't let sd-image-aarch64.nix setup serial console as it breaks bluetooth.
      "console=tty0"
      # allow GPIO access
      "iomem=relaxed"
      "strict-devmem=0"
      # booting sometimes fails with an oops in the ethernet driver. reboot after 5s
      "panic=5"
      "oops=panic"
      # for the patch below
      "compat_uts_machine=armv6l"
    ];

    tmp.useTmpfs = true;
    tmp.tmpfsSize = "80%";
  };
  fileSystems."/" = lib.mkForce {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };

  fileSystems."/home/goeranh/ssd" = lib.mkForce {
    device = "/dev/disk/by-label/store";
    fsType = "btrfs";
  };

  goeranh = {
    server = true;
    trust-builder = true;
    update = true;
    monitoring = false;
  };

  networking = {
    hostName = "pitest"; # Define your hostname.
    nftables.enable = true;
    useDHCP = false;
    firewall = {
      enable = true;
      interfaces = {
        "wg0".allowedTCPPorts = [ 22 ];
        "eth0".allowedTCPPorts = [ 22 ];
      };
    };

  };

  nix = {
    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";
    settings = {
      builders-use-substitutes = true;
      cores = 4;
      #extra-platforms = "armv6l-linux";
    };
  };

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
  ];

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  sdImage.compressImage = false;

  services = {
    # Do not log to flash:
    journald.extraConfig = ''
      Storage=volatile
    '';
  };

  systemd = {
    network = {
      enable = true;
      netdevs = {
        # "10-wg0" = {
        #   netdevConfig = {
        #     Kind = "wireguard";
        #     Name = "wg0";
        #     MTUBytes = "1300";
        #   };
        #   wireguardConfig = {
        #     PrivateKeyFile = "/var/lib/wireguard/private";
        #     ListenPort = 9918;
        #   };
        #   wireguardPeers = [
        #     {
        #       wireguardPeerConfig = {
        #         PublicKey = "fvGBgD6oOqtcgbbLXDRptL1QomkSlKh29I9EhYQx1iw=";
        #         AllowedIPs = [ "10.200.0.0/24" "10.0.0.0/24" "10.0.1.0/24" ];
        #         Endpoint = "49.13.134.146:51820";
				# 				PersistentKeepalive = 30;
        #       };
        #     }
        #   ];
        # };
      };
      networks = {
        eth0 = {
          matchConfig.Name = "eth0";
          address = [
            "192.168.2.15/24"
          ];
          DHCP = "no";
          gateway = [
            "192.168.2.1"
          ];
          networkConfig = {
            IPv6AcceptRA = false;
          };
        };
        # wg0 = {
        #   matchConfig.Name = "wg0";
        #   address = [
        #     "10.200.0.4/24"
        #   ];
        #   DHCP = "no";
        #   routes = [
				# 	  {
				# 			routeConfig = {
				# 				Gateway = "10.200.0.5";
				# 				Destination = "10.0.0.0/24";
				# 			};
				# 		}
				# 	  {
				# 			routeConfig = {
				# 				Gateway = "10.200.0.5";
				# 				Destination = "10.0.1.0/24";
				# 			};
				# 		}
				# 	];
        #   networkConfig = {
        #     IPv6AcceptRA = false;
        #   };
        # };
      };
    };
    services = {
      nix-daemon.serviceConfig = {
        LimitNOFILE = lib.mkForce 8192;
        CPUWeight = 5;
        MemoryHigh = "4G";
        MemoryMax = "6G";
        MemorySwapMax = "0";
      };
    };
  };

  system.stateVersion = "23.11"; # Did you read the comment?
}

