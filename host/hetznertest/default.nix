{ config, pkgs, lib, ... }: {
  nixpkgs.hostPlatform = "x86_64-linux";
  boot = {
    initrd = {
      availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
      kernelModules = [ ];
    };
    kernelModules = [ ];
    extraModulePackages = [ ];
    loader.grub.device = "/dev/sda";
  };

  networking = {
    useDHCP = true;
    hostName = "hetznertest";
    firewall.allowedTCPPorts = [ 22 ];
  };
  goeranh = {
    server = true;
    #    defaultdisco = true;
  };
  users.users.goeranh.password = "test";
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };
  system.stateVersion = "23.05"; # Did you read the comment?
}
