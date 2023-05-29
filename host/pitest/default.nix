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
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  goeranh = {
    server = true;
  };

  networking = {
    hostName = "pitest"; # Define your hostname.
    useDHCP = true;
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
  # kernel 32bit personality patch from Ubuntu
  # boot.kernelPatches = [
  #   rec {
  #     name = "compat_uts_machine";
  #     patch = pkgs.fetchpatch {
  #       inherit name;
  #       url = "https://git.launchpad.net/~ubuntu-kernel/ubuntu/+source/linux/+git/jammy/patch/?id=c1da50fa6eddad313360249cadcd4905ac9f82ea";
  #       sha256 = "sha256-mpq4YLhobWGs+TRKjIjoe5uDiYLVlimqWUCBGFH/zzU=";
  #     };
  #   }
  # ];

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
    vim
    wget
    libva-utils
  ];

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

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
  };

  system.stateVersion = "21.05"; # Did you read the comment?
}

