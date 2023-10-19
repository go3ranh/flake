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
      device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0";
      fsType = "ext4";
    };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Bootloader.
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
    useOSProber = true;
  };
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  networking = {
    hostName = "fileserver";
    #firewall = {
    #  interfaces."tailscale0".allowedTCPPorts = [ 80 443 ];
    #  allowedTCPPorts = [ 22 ];
    #  enable = true;
    #};
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
    development = true;
    remote-store = true;
    update = true;
  };
  environment.systemPackages = with pkgs; [
  ];

  system.stateVersion = "23.05"; # Did you read the comment?
}
