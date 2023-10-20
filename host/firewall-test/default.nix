{ config, pkgs, lib, ... }:

{
  boot = {
    initrd = {
      availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
      kernelModules = [ ];
    };
    kernelModules = [ ];
    extraModulePackages = [ ];
  };

  fileSystems."/" =
    {
      #todo
      device = "/dev/disk/by-uuid/dc5071c0-ceec-4bf0-8193-8401487e8284";
      fsType = "ext4";
    };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/0500c8e8-069e-4cf7-92fb-3e2ee148c5b6"; }];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Bootloader.
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
    useOSProber = true;
  };
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  networking = {
    hostName = "firewall-test";
    nftables.enable = true;
    networkmanager.enable = true;
    firewall = {
      #allowedTCPPorts = [ 22 ];
      enable = true;
    };
    #interfaces.ens18.ipv4.addresses = [{
    #  address = "192.168.178.124";
    #  prefixLength = 24;
    #}];
    #defaultGateway = "192.168.178.1";
    #nameservers = [ "1.1.1.1" "9.9.9.9" ];
  };
  services = {
    qemuGuest.enable = true;
  };

  goeranh = {
    server = true;
    update = true;
  };
  environment.systemPackages = with pkgs; [
  ];

  system.stateVersion = "23.05"; # Did you read the comment?
}
