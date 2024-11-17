{ inputs, config, lib, pkgs, ... }:

{
  boot.plymouth = {
    enable = true;
  };
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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
              AllowedIPs = [ "10.200.0.0/24" "10.0.0.0/24" ];
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
            "10.200.0.12/24"
          ];
          DHCP = "no";
          networkConfig = {
            IPv6AcceptRA = false;
          };
        };
        eth = {
          matchConfig.Name = "enp0s31f6";
          DHCP = "ipv4";
          networkConfig = {
            IPv6AcceptRA = true;
          };
        };
      };
    };
  };
  networking = {
    hostName = "node6";
    networkmanager.enable = true;
  };
  virtualisation.libvirtd.enable = true;
  programs.dconf.enable = true;

  programs.git.enable = true;

  hardware.pulseaudio.enable = false;
  services = {
    fwupd.enable = true;
    jack = {
      jackd.enable = true;
      alsa.enable = false;
      loopback = {
        enable = true;
      };
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = false;
    };
    gnome = {
      gnome-keyring.enable = true;
    };
    #printing.enable = true;
    #avahi.enable = true;
    #avahi.nssmdns = true;
    openssh.enable = lib.mkForce false;

  };

  # services.printing.enable = true;
  # programs.hyprland = {
  #   enable = true;
  #   package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
  # };

  goeranh = {
    desktop = true;
    development = true;
    monitoring = false;
  };

  environment.systemPackages = with pkgs; [
    neovim
    tmux
    wget

    # hyprpaper
    kitty
    libnotify
    mako
    qt5.qtwayland
    qt6.qtwayland
    swayidle
    swaylock-effects
    wlogout
    wl-clipboard
    wofi
    waybar
  ];


  zramSwap = {
    enable = true;
  };

  system.stateVersion = "24.05"; # Did you read the comment?

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_11;

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/30783b24-0831-4621-a16a-7a9daac30a12";
      fsType = "btrfs";
      options = [ "subvol=root" "compress=zstd" ];
    };

  fileSystems."/home" =
    {
      device = "/dev/disk/by-uuid/30783b24-0831-4621-a16a-7a9daac30a12";
      fsType = "btrfs";
      options = [ "subvol=home" "compress=zstd" ];
    };

  fileSystems."/var" =
    {
      device = "/dev/disk/by-uuid/30783b24-0831-4621-a16a-7a9daac30a12";
      fsType = "btrfs";
      options = [ "subvol=var" "compress=zstd" ];
    };

  fileSystems."/nix" =
    {
      device = "/dev/disk/by-uuid/30783b24-0831-4621-a16a-7a9daac30a12";
      fsType = "btrfs";
      options = [ "subvol=nix" "compress=zstd" ];
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/12CE-A600";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp0s31f6.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp4s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware = {
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
    #enableAllFirmware = true;
  };
}
