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
      "console=tty0"
      "iomem=relaxed"
      "strict-devmem=0"
      "panic=5"
      "oops=panic"
      "compat_uts_machine=armv6l"
    ];

    tmp.useTmpfs = true;
    tmp.tmpfsSize = "80%";
  };
  fileSystems."/" = lib.mkForce {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };

  goeranh = {
    server = true;
  };

  #networking = {
  #  hostName = "pitest"; # Define your hostname.
  #  domain = "tailf0ec0.ts.net";
  #  nftables.enable = true;
  #  useDHCP = false;
  #  interfaces.eth0.ipv4.addresses = [{
  #    address = "192.168.178.2";
  #    prefixLength = 24;
  #  }];
  #  defaultGateway = "192.168.178.1";
  #  nameservers = [ "1.1.1.1" "8.8.8.8" ];

  #  firewall.enable = true;
  #  firewall.allowedTCPPorts = [ 80 443 ];
  #};

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

  systemd = {
    services.nix-daemon.serviceConfig = {
      LimitNOFILE = lib.mkForce 8192;
      CPUWeight = 5;
      MemoryHigh = "4G";
      MemoryMax = "6G";
      MemorySwapMax = "0";
    };
    network = {
      enable = true;
      networks."10-lan" = {
        enable = true;
        matchConfig.Name = "eth0";
        address = [ "192.168.178.3/24" ];
        gateway = [ "192.168.178.1" ];
        dns = [ "1.1.1.1" "9.9.9.9" ];
        routes = [
          { routeConfig.Gateway = "192.168.178.1"; }
          {
            routeConfig = {
              Gateway = "192.168.178.1";
              GatewayOnLink = true;
            };
          }
        ];
      };
    };
  };

  system.stateVersion = "23.05"; # Did you read the comment?
}

