{ config, pkgs, lib, ... }:

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
    firewall.allowedTCPPorts = [ 22 ];
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
        owner = "harmonia";
        #group = "root";
        mode = "0400";
      };
    };
  };

  goeranh = {
    server = true;
    development = true;
    remote-store = true;
    update = true;
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
          locations = {
            "/" = {
              proxyPass = "http://localhost:8081";
            };
            "/hydra/" = {
              proxyPass = "http://localhost:3000";
              #extraConfig = ''
              #  rewrite ^/git(.*)$ $1 break;
              #'';
            };
          };
        };
      };
    };
    #hydra = {
    #  enable = true;
    #  buildMachinesFiles = [
    #    "/etc/nix/machines"
    #    "/var/lib/hydra/machines"
    #  ];
    #  hydraURL = "https://hydra.hq.c3d2.de";
    #  ldap.enable = true;
    #  logo = ./c3d2.svg;
    #  minimumDiskFree = 50;
    #  minimumDiskFreeEvaluator = 50;
    #  notificationSender = "hydra@spam.works";
    #  useSubstitutes = true;
    #  extraConfig =
    #    let
    #      key = config.sops.secrets."nix/signing-key/secretKey".path;
    #    in
    #    ''
    #      binary_cache_secret_key_file = ${key}
    #      compress_num_threads = 4
    #      evaluator_workers = 4
    #      evaluator_max_memory_size = 2048
    #      max_output_size = ${toString (5*1024*1024*1024)} # sd card and raw images
    #      store_uri = auto?secret-key=${key}&write-nar-listing=1&ls-compression=zstd&log-compression=zstd
    #      upload_logs_to_binary_cache = true
    #    '';
    #};

    ## A rust nix binary cache
    #harmonia = {
    #  enable = true;
    #  settings = {
    #    bind = "[::]:${toString cachePort}";
    #    workers = 20;
    #    max_connection_rate = 1024;
    #    priority = 50;
    #  };
    #  signKeyPath = config.sops.secrets."nix/signing-key/secretKey".path;
    #};
  };


  system.stateVersion = "23.05"; # Did you read the comment?

}
