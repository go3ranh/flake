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
  systemd.services = {
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
  nix = {
    # distributedBuilds = true;
    # extraOptions = ''
    #   			builders-use-substitutes = true
    #   		'';
    # buildMachines = [
    #   {
    #     maxJobs = 50;
    #     protocol = "ssh-ng";
    #     hostName = "kbuild";
    #     publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUp0SGRJaHNPVTNvenExQklLRTZmMWUwS2pMbG91MTNtUU1waFkyYTBlVDQgcm9vdEBidWlsZHZtMQo=";
    #     sshKey = "/home/goeranh/.ssh/wgidng";
    #     sshUser = "goeranh";
    #     supportedFeatures = [
    #       "nixos-test"
    #       "benchmark"
    #       "big-parallel"
    #       "kvm"
    #     ];
    #     speedFactor = 10;
    #     systems = [ "x86_64-linux" "aarch64-linux" "i686-linux" ];
    #   }
    # ];
  };

  #zramSwap = {
  #  enable = true;
  #};

  networking = {
    hostName = "node5";
    networkmanager.enable = true;
    hosts = {
      "127.0.0.2" = [ "youtube.com" "*.youtube.com" ];
    };
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
      "testfile" = {
        owner = "root";
        group = "root";
        mode = "0400";
      };
    };
  };



  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
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
  };

  hardware.hackrf.enable = true;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "electron-25.9.0"
  ];

  environment.systemPackages = with pkgs; [
    usbutils
    iftop
    ifuse
    libimobiledevice
    lm_sensors
    lsof
    smartmontools
  ]; # ++ [ self.packages.x86_64-linux.proxmark ];

  virtualisation.libvirtd.enable = true;
  virtualisation.podman.enable = true;
  virtualisation.podman.dockerCompat = true;
  programs.dconf.enable = true;

  programs.git.enable = true;
  # networking.firewall.allowedTCPPorts = [ 22 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  networking.firewall.enable = true;

  system.stateVersion = "23.11";


  services = {
    fwupd.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = false;
    };
    #printing.enable = true;
    #avahi.enable = true;
    #avahi.nssmdns = true;
    openssh.enable = false;
    #usbmuxd = {
    #  enable = true;
    #  package = pkgs.usbmuxd2;
    #};

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

  swapDevices = (map
    (diskName: {
      device = zfsRoot.devNodes + diskName + zfsRoot.partitionScheme.swap;
      discardPolicy = "both";
      randomEncryption = {
        enable = true;
        allowDiscards = true;
      };
    })
    zfsRoot.bootDevices);

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.cpu.amd.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.enableRedistributableFirmware = true;

  boot.supportedFilesystems = [ "zfs" "ntfs" ];
  networking.hostId = "2b34dd1b";
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  boot.loader.efi.efiSysMountPoint = with builtins;
    (zfsRoot.mirroredEfi + (head zfsRoot.bootDevices) + zfsRoot.partitionScheme.efiBoot);
  boot.zfs.devNodes = zfsRoot.devNodes;
  boot.loader.efi.canTouchEfiVariables = false;
  boot.loader.generationsDir.copyKernels = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.enable = true;
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

