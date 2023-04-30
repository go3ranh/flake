{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/106e55e4-3573-4773-84a9-efd5cbd5d024";
      fsType = "ext4";
    };

  fileSystems."/home/goeranh/ssd" =
    {
      device = "/dev/disk/by-uuid/b803d9e3-5244-4d33-bac5-f50290e83ee6";
      fsType = "ext4";
    };

  fileSystems."/boot/efi" =
    {
      device = "/dev/disk/by-uuid/7248-DC33";
      fsType = "vfat";
    };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/b6c55388-5f12-4de1-877b-6c2f9f36a72c"; }];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
