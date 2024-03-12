{ config, pkgs, lib, ... }:
let
  cachePort = 8080;
in
{
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/832ec016-7d26-4a86-813b-ec375f698262";
      fsType = "ext4";
    };

  swapDevices = [ ];

  networking = {
    useDHCP = true;
    hostName = "kbuild";
    firewall.allowedTCPPorts = [ 22 80 443 ];
  };

  nixpkgs.hostPlatform = "x86_64-linux";

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  sops = {
    # This will automatically import SSH keys as age keys
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = ./secrets.yaml;
    defaultSopsFormat = "yaml";
    secrets = {
      "privateCacheKey" = {
        owner = "root";
        #group = "root";
        mode = "0400";
      };
      "nextcloud-admin-pass" = {
        owner = "nextcloud";
        group = "nextcloud";
        mode = "0440";
      };
    };
  };

  nix.settings.secret-key-files = [ "${config.sops.secrets.privateCacheKey.path}" ];

  goeranh = {
    server = true;
    development = true;
    remote-store = true;
  };
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  services = {
    nginx = {
      enable = true;
      virtualHosts = {
        "${config.networking.fqdn}" = {
          sslCertificate = "/var/lib/${config.networking.fqdn}.crt";
          sslCertificateKey = "/var/lib/${config.networking.fqdn}.key";
          forceSSL = true;
        };
      };
    };
		nextcloud = {
			enable = true;
      hostName = "${config.networking.fqdn}";

       # Need to manually increment with every major upgrade.
      package = pkgs.nextcloud28;

      # Let NixOS install and configure the database automatically.
      database.createLocally = true;

      # Let NixOS install and configure Redis caching automatically.
      configureRedis = true;

      # Increase the maximum file upload size to avoid problems uploading videos.
      maxUploadSize = "16G";
      https = true;

      autoUpdateApps.enable = true;
      extraAppsEnable = true;
      extraApps = with config.services.nextcloud.package.packages.apps; {
        inherit calendar contacts mail notes tasks music; # onlyoffice 
      };

      config = {
        overwriteProtocol = "https";
        defaultPhoneRegion = "DE";
        # dbtype = "pgsql";
        adminuser = "admin";
        adminpassFile = "${config.sops.secrets.nextcloud-admin-pass.path}";
      };
		};
		# onlyoffice = {
    #   enable = true;
    #   hostname = "${config.networking.fqdn}";
    # };
  };


  system.stateVersion = "23.11"; # Did you read the comment?

}
