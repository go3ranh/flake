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
    hostName = "nixserver";
    networkmanager.enable = true;
    firewall = {
      interfaces."tailscale0".allowedTCPPorts = [ 80 443 ];
      allowedTCPPorts = [ 22 ];
      enable = true;
    };
    interfaces.ens18.ipv4.addresses = [{
      address = "192.168.178.124";
      prefixLength = 24;
    }];
    defaultGateway = "192.168.178.1";
    nameservers = [ "1.1.1.1" "9.9.9.9" ];
  };
  services = {
    qemuGuest.enable = true;
    hydra = {
      enable = true;
      hydraURL = "http://${config.networking.fqdn}/hydra/";
      notificationSender = "hydra@hydra.local";
      listenHost = "localhost";
      extraConfig = ''
        using_frontend_proxy 1
        base_uri https://${config.networking.fqdn}/hydra/
      '';
    };
    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts."${config.networking.fqdn}" = {
        serverAliases = [ "${config.networking.hostName}" ];
        sslCertificate = "/var/lib/nixserver.tailf0ec0.ts.net.crt";
        sslCertificateKey = "/var/lib/nixserver.tailf0ec0.ts.net.key";
        onlySSL = true;
        locations."/hydra" = {
          proxyPass = "http://127.0.0.1:3000";
          recommendedProxySettings = true;
          extraConfig = ''
            proxy_set_header        Host              $host;
            proxy_set_header        X-Real-IP         $remote_addr;
            proxy_set_header        X-Forwarded-For   $proxy_add_x_forwarded_for;
            proxy_set_header        X-Forwarded-Proto $scheme;
            proxy_set_header        X-Request-Base     /hydra;
          '';
        };
      };
    };
  };

  goeranh = {
    server = true;
    development = true;
    remote-store = true;
    update = true;
  };
  environment.systemPackages = with pkgs; [
    waypipe
  ];

  system.stateVersion = "23.05"; # Did you read the comment?
}
