{ self, config, lib, pkgs, ... }:

let
  zfsRoot.partitionScheme = {
    biosBoot = "-part5";
    efiBoot = "-part1";
    swap = "-part4";
    bootPool = "-part2";
    rootPool = "-part3";
  };
  zfsRoot.devNodes = "/dev/disk/by-id/"; # MUST have trailing slash! /dev/disk/by-id/
  zfsRoot.bootDevices = (import ./machine.nix).bootDevices;
  zfsRoot.mirroredEfi = "/boot/efis/";

in
{
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
          };
          wireguardPeers = [
            {
              PublicKey = "fvGBgD6oOqtcgbbLXDRptL1QomkSlKh29I9EhYQx1iw=";
              AllowedIPs = [ "fd8:393:5efa:343::/64" "fd14:5d1a:7fd7:34e8::" "10.0.0.0/8" ];
              Endpoint = "49.13.134.146:1194";
              PersistentKeepalive = 30;
            }
          ];
        };
        # "11-wg1" = {
        #   netdevConfig = {
        #     Kind = "wireguard";
        #     Name = "wg1";
        #     MTUBytes = "1300";
        #   };
        #   wireguardConfig = {
        #     PrivateKeyFile = "/var/lib/wireguard/private";
        #   };
        #   wireguardPeers = [
        #     {
        # 				PublicKey = "/xN0cEPxD9mS/Zq2DCfPfn9AxlpZxODBrXtJdeNr4gw=";
        # 				AllowedIPs = [ "10.230.0.0/24" ];
        # 				Endpoint = "goeranh.de:1194";
        #     }
        #   ];
        # };
        "20-br0" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "br0";
          };
        };
      };
      networks = {
        wg0 = {
          matchConfig.Name = "wg0";
          address = [
            "10.200.0.2/24"
            "fd8:393:5efa:343::2/64"
          ];
          # gateway = [ "10.200.0.5" ];
          routes = [
            {
              Gateway = "fd8:393:5efa:343::100";
              Destination = "fd14:5d1a:7fd7:34e8::/64";
            }
            {
              Gateway = "10.200.0.100";
              Destination = "10.0.0.0/24";
            }
            # {
            # 		Gateway = "10.200.0.100";
            # 		Destination = "10.1.1.0/24";
            # }
            # {
            # 		Gateway = "10.200.0.5";
            # 		Destination = "10.16.17.0/21";
            # }
          ];
          dns = [
            "10.200.0.100"
          ];
          networkConfig = {
            IPv6AcceptRA = true;
          };
        };
        # wg1 = {
        #   matchConfig.Name = "wg1";
        #   address = [
        #     "10.230.0.2/24"
        #   ];
        #   DHCP = "no";
        #   networkConfig = {
        #     IPv6AcceptRA = false;
        #   };
        # };
        "40-br0" = {
          matchConfig.Name = "br0";
          bridgeConfig = { };
          # Disable address autoconfig when no IP configuration is required
          networkConfig.LinkLocalAddressing = "no";
          address = [
            "10.20.0.1/24"
          ];
          networkConfig = {
            # or "routable" with IP addresses configured
            #RequiredForOnline = "carrier";
            ConfigureWithoutCarrier = true;
          };
        };
      };
    };
    services = {
      ModemManager.enable = false;
      zfs-mount.enable = false;
      NetworkManager-wait-online.enable = false;
      home-snapshot = {
        path = [
          pkgs.zfs
        ];
        script = "zfs snap rpool/nixos/home@$(date +%d-%m-%Y-%H-%M)";
        serviceConfig = {
          User = config.users.users.goeranh.name;
        };
        startAt = "hourly";
      };
      home-backup = {
        path = [
          pkgs.zfs
          pkgs.openssh
          pkgs.iproute2
          pkgs.gawk
        ];
        script = builtins.readFile ./backup;
        serviceConfig = {
          User = config.users.users.root.name;
        };
        startAt = "hourly";
      };
      var-snapshot = {
        path = [
          pkgs.zfs
        ];
        script = "zfs snap -r rpool/nixos/var@$(date +%d-%m-%Y-%H-%M)";
        serviceConfig = {
          User = config.users.users.goeranh.name;
        };
        startAt = "weekly";
      };
    };
  };

  documentation = {
    man = {
      man-db.enable = true;
      #mandoc.enable = true;
      generateCaches = true;
    };
    nixos.enable = true;
    dev.enable = true;
  };

  networking = {
    hostName = "node5";
    networkmanager.enable = true;
    hosts = {
      "127.0.0.2" = [ "youtube.com" "*.youtube.com" ];
      "10.20.0.2" = [ "ipa.goeranh.lan" ];
      "10.30.0.2" = [ "ipa.goeranh.test" ];
    };

    nat = {
      enable = true;
      internalInterfaces = [ "br0" ];
      externalInterface = "wlp0s20f3";
      enableIPv6 = false;
    };
    wireless.enable = lib.mkForce false;
  };

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  sops = {
    # This will automatically import SSH keys as age keys
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = ./secrets.yaml;
    defaultSopsFormat = "yaml";
    secrets = {
      "signingkey" = {
        owner = "root";
        group = "root";
        mode = "0400";
      };
    };
  };



  security = {
    rtkit.enable = true;
    polkit.enable = true;
    sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };
  };

  goeranh = {
    desktop = true;
    trust-builder = true;
    development = true;
    update = true;
    monitoring = false;
  };

  hardware.hackrf.enable = true;

  nixpkgs.config.allowUnfree = true;
  nix.settings.trusted-users = [
    "goeranh"
  ];

  environment.systemPackages = with pkgs; [
    usbutils
    iftop
    ifuse
    libimobiledevice
    lm_sensors
    lsof
    smartmontools
  ];

  virtualisation.libvirtd.enable = true;
  programs.dconf.enable = true;
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/home/goeranh/gitprojects/src/gitlab.goeranh.de/goeranh/flakeathome";
  };

  programs.git.enable = true;

  networking.firewall.enable = true;

  system.stateVersion = "23.11";


  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  services = {
    postgresql = {
      enable = true;
      ensureUsers = [
        {
          name = "goeranh";
          ensureClauses = {
            superuser = true;
            createrole = true;
            createdb = true;
          };
        }
      ];
    };
    fwupd.enable = true;
    resolved = lib.mkForce {
      enable = true;
      fallbackDns = [ "10.200.0.100" ]; #"9.9.9.9" ];
    };
    jack = {
      jackd.enable = false;
      alsa.enable = false;
      loopback = {
        enable = false;
      };
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
    gnome = {
      gnome-keyring.enable = true;
    };
    printing.enable = false;
    #avahi.enable = true;
    #avahi.nssmdns = true;
    openssh.enable = lib.mkForce false;

    mysql = {
      enable = true;
      package = pkgs.mariadb;
      ensureDatabases = [
        "shop"
        "datanature"
      ];
      ensureUsers = [
        {
          name = "goeranh";
          ensurePermissions = {
            "shop.*" = "ALL PRIVILEGES";
            "datanature.*" = "ALL PRIVILEGES";
          };
        }
      ];
    };
  };

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  boot.initrd.availableKernelModules = [
    "ahci"
    "xhci_pci"
    "virtio_pci"
    "virtio_blk"
    "ehci_pci"
    "nvme"
    "uas"
    "sd_mod"
    "sr_mod"
    "sdhci_pci"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" "kvm-amd" ];
  boot.kernel.sysctl = {
    "vm.swappiness" = 80;
  };
  boot.kernelParams = [
    "i915.enable_psr=0"
  ];

  fileSystems = {
    "/" = {
      device = "rpool/nixos/root";
      fsType = "zfs";
      options = [ "X-mount.mkdir" ];
    };

    "/home" = {
      device = "rpool/nixos/home";
      fsType = "zfs";
      options = [ "X-mount.mkdir" ];
    };

    "/var/lib" = {
      device = "rpool/nixos/var/lib";
      fsType = "zfs";
      options = [ "X-mount.mkdir" ];
    };

    "/var/log" = {
      device = "rpool/nixos/var/log";
      fsType = "zfs";
      options = [ "X-mount.mkdir" ];
    };

    "/boot" = {
      device = "bpool/nixos/root";
      fsType = "zfs";
      options = [ "X-mount.mkdir" ];
    };
  } // (builtins.listToAttrs (map
    (diskName: {
      name = zfsRoot.mirroredEfi + diskName + zfsRoot.partitionScheme.efiBoot;
      value = {
        device = zfsRoot.devNodes + diskName + zfsRoot.partitionScheme.efiBoot;
        fsType = "vfat";
        options = [
          "x-systemd.idle-timeout=1min"
          "x-systemd.automount"
          "noauto"
          "nofail"
        ];
      };
    })
    zfsRoot.bootDevices));

  zramSwap = {
    enable = true;
  };

  # swapDevices = (map
  #   (diskName: {
  #     device = zfsRoot.devNodes + diskName + zfsRoot.partitionScheme.swap;
  #     discardPolicy = "both";
  #     randomEncryption = {
  #       enable = true;
  #       allowDiscards = true;
  #     };
  #   })
  #   zfsRoot.bootDevices);

  #networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.cpu.amd.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.enableRedistributableFirmware = true;

  boot.supportedFilesystems = [ "zfs" "ntfs" ];
  networking.hostId = "2b34dd1b";
  #boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  boot.loader.efi.efiSysMountPoint = with builtins;
    (zfsRoot.mirroredEfi + (head zfsRoot.bootDevices) + zfsRoot.partitionScheme.efiBoot);
  boot.zfs.devNodes = zfsRoot.devNodes;
  boot.loader.efi.canTouchEfiVariables = false;
  boot.loader.generationsDir.copyKernels = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.enable = lib.mkForce true;
  boot.loader.grub.copyKernels = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.zfsSupport = true;
  boot.loader.grub.extraInstallCommands = with builtins;
    (toString (map
      (diskName:
        "cp -r " + config.boot.loader.efi.efiSysMountPoint + "/EFI" + " "
        + zfsRoot.mirroredEfi + diskName + zfsRoot.partitionScheme.efiBoot + "\n")
      (tail zfsRoot.bootDevices)));
  boot.loader.grub.devices =
    (map (diskName: zfsRoot.devNodes + diskName) zfsRoot.bootDevices);
}

