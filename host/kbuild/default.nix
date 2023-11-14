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
    };
  };

  nix.settings.secret-key-files = [ "${config.sops.secrets.privateCacheKey.path}" ];

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
              proxyPass = "http://localhost:${toString cachePort}";
            };
          };
        };
      };
    };
    hydra = {
      enable = true;
      hydraURL = "http://localhost:3000";
      minimumDiskFree = 20;
      minimumDiskFreeEvaluator = 50;
      notificationSender = "notify@hydra.local";
      useSubstitutes = true;
      extraConfig =
        let
          key = config.sops.secrets."privateCacheKey".path;
        in
        ''
          binary_cache_secret_key_file = ${key}
          compress_num_threads = 4
          evaluator_workers = 4
          store_uri = auto?secret-key=${key}&write-nar-listing=1&ls-compression=zstd&log-compression=zstd
          upload_logs_to_binary_cache = true
        '';
    };
  };


  system.stateVersion = "23.05"; # Did you read the comment?

}
