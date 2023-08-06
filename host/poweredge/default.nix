{ inputs, config, pkgs, lib, ... }:
let
  hostname = "nixbuild";
  domainname = "tailf0ec0.ts.net";
in
{
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.ens18.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;


  # Bootloader.
  disko.devices = import ./disk-config.nix {
    lib = lib;
  };
  boot.loader.grub = {
    devices = [ "/dev/sda" ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  #boot.loader.grub.enable = true;
  #boot.loader.grub.device = "/dev/sda";
  #boot.loader.grub.useOSProber = true;

  networking = {
    hostName = "${hostname}";
    interfaces.eno1.addresses = [
      {
        address = "192.168.178.123";
        prefixLength = 24;
      }
    ];
	defaultGateway = "192.168.178.1";
	firewall.allowedTCPPorts = [ 22 ];
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

  environment.systemPackages = with pkgs; [
    vim
    zellij
    tmux
    htop
    wget
  ];

  services = {
    openssh = {
      enable = true;
    };
    tailscale = {
      enable = true;
    };
  };

  programs = {
    git = {
      enable = true;
    };

    neovim = {
      enable = true;
    };
  };

  system.stateVersion = "22.11"; # Did you read the comment?
}
