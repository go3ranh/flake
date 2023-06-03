{ config, pkgs, lib, ... }:
{
  hardware.enableRedistributableFirmware = true;
  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";

  nixpkgs.config.packageOverrides = pkgs: {
    makeModulesClosure = x:
      # prevent kernel install fail due to missing modules
      pkgs.makeModulesClosure (x // { allowMissing = true; });
  };

  boot = {
    # repeat https://github.com/NixOS/nixos-hardware/blob/master/raspberry-pi/4/default.nix#L20
    # to overwrite audio module
    kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
    # loader.raspberryPi = {
    #   enable = true;
    #   version = 4;
    #   firmwareConfig = ''
    #     gpu_mem=256
    #     dtparam=audio=on
    #   '';
    # };

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

  users.ldap = {
    enable = true;
    useTLS = true;
    server = "ldaps://nixpi1.tailf0ec0.ts.net";
    base = "dc=tailf0ec0,dc=ts,dc=net";
    bind = {
      policy = "soft";
      distinguishedName = "cn=admin,dc=tailf0ec0,dc=ts,dc=net";
      passwordFile = "/var/lib/smbpasswd";
    };
  };

  goeranh = {
    server = true;
  };

  networking = {
    hostName = "pitest"; # Define your hostname.
    useDHCP = false;
    interfaces.eth0.ipv4.addresses = [{
      address = "192.168.178.2";
      prefixLength = 24;
    }];
    defaultGateway = "192.168.178.1";
    nameservers = [ "1.1.1.1" "8.8.8.8" ];

    firewall.enable = true;
  };

  nix = {
    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";
    settings = {
      builders-use-substitutes = true;
      cores = 4;
      extra-platforms = "armv6l-linux";
      max-jobs = 1;
      system-features = [ ];
      trusted-users = [ "client" ];
    };
  };

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
    vim
    tmux
    wget
  ];

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };
  sdImage.compressImage = false;

  console.keyMap = "de";

  services = {
    # Do not log to flash:
    journald.extraConfig = ''
      Storage=volatile
    '';
  };
  virtualisation.libvirtd.enable = true;

  systemd = {
    services.nix-daemon.serviceConfig = {
      LimitNOFILE = lib.mkForce 8192;
      CPUWeight = 5;
      MemoryHigh = "4G";
      MemoryMax = "6G";
      MemorySwapMax = "0";
    };
  };

  system.stateVersion = "22.11"; # Did you read the comment?
}

