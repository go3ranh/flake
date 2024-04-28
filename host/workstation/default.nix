{ config, pkgs, lib, ... }:

{
  boot = {
    binfmt.emulatedSystems = [ "aarch64-linux" ];
    kernelModules = [ ];
    extraModulePackages = [ ];
    initrd = {
      availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
      kernelModules = [ ];
    };
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/6d1f76d6-961b-44c7-98ff-d020ecbce7b4";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/D80A-1208";
      fsType = "vfat";
    };
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      trusted-public-keys = [
        "nixbsd:gwcQlsUONBLrrGCOdEboIAeFq9eLaDqfhfXmHZs1mgc="
      ];
      trusted-substituters = [
        "https://attic.mildlyfunctional.gay/nixbsd"
      ];
    };
  };

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;

  networking.hostName = "workstation";
  time.timeZone = "Europe/Berlin";

  virtualisation.libvirtd.enable = true;
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICt3IRfe/ysPl8jKMgYYlo2EEDnoyyQ/bY2u6qqMuWsQ goeranh@node5"
  ];

  security.sudo.wheelNeedsPassword = false;
  goeranh = {
    server = true;
    update = true;
  };

  services = {
    openssh.settings.X11Forwarding = true;
  };

  networking.firewall.allowedTCPPorts = [ 8080 1980 ];
  networking.firewall.interfaces.wt0.allowedTCPPorts = [ 9002 ];
  system.stateVersion = "23.11";
}

