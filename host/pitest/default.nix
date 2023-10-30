{ config, pkgs, lib, ... }:
{
  hardware.enableRedistributableFirmware = true;
  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";

  nixpkgs.config.packageOverrides = pkgs: {
    makeModulesClosure = x:
      # prevent kernel install fail due to missing modules
      pkgs.makeModulesClosure (x // { allowMissing = true; });
  };

  boot = {
    # repeat https://github.com/NixOS/nixos-hardware/blob/master/raspberry-pi/4/default.nix#L20
    # to overwrite audio module
    kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;

    kernelParams = lib.mkForce [
      "snd_bcm2835.enable_headphones=1"
      # don't let sd-image-aarch64.nix setup serial console as it breaks bluetooth.
      "console=tty0"
      # allow GPIO access
      "iomem=relaxed"
      "strict-devmem=0"
      # booting sometimes fails with an oops in the ethernet driver. reboot after 5s
      "panic=5"
      "oops=panic"
      # for the patch below
      "compat_uts_machine=armv6l"
    ];

    tmp.useTmpfs = true;
    tmp.tmpfsSize = "80%";
  };
  fileSystems."/" = lib.mkForce {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };

  fileSystems."/home/goeranh/ssd" = lib.mkForce {
    device = "/dev/disk/by-label/store";
    fsType = "btrfs";
  };

  goeranh = {
    server = true;
    trust-builder = true;
    update = true;
    update-user = "goeranh";
  };

  networking = {
    hostName = "pitest"; # Define your hostname.
    nftables.enable = true;
    useDHCP = false;
    interfaces.eth0.ipv4.addresses = [{
      address = "192.168.178.2";
      prefixLength = 24;
    }];
    defaultGateway = "192.168.178.1";
    nameservers = [ "1.1.1.1" "8.8.8.8" ];

    firewall.enable = true;
    firewall.allowedTCPPorts = [ 80 443 2222 ];
    nat = {
      enable = true;
      internalInterfaces = [ "ve-+" ];
      externalInterface = "eth0";
    };
  };

  nix = {
    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";
    settings = {
      builders-use-substitutes = true;
      cores = 4;
      extra-platforms = "armv6l-linux";
      #max-jobs = 1;
      #system-features = [ ];
      #trusted-users = [ "client" ];
    };
  };

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
  ];

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  sdImage.compressImage = false;

  services = {
    # Do not log to flash:
    journald.extraConfig = ''
      Storage=volatile
    '';
    gitea = {
      enable = true;
      settings = {
        service.DISABLE_REGISTRATION = true;
        server = {
          ROOT_URL = "https://${config.networking.fqdn}/git/";
          WORK_PATH = "/var/lib/gitea";
          DISABLE_SSH = false;
          DOMAIN = "${config.networking.fqdn}";
          SSH_DOMAIN = "${config.networking.fqdn}";
          SSH_PORT = 2222;
          START_SSH_SERVER = true;
        };
        log.LEVEL = "Warn";
      };
      package = pkgs.forgejo;
    };
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
            "/git/" = {
              proxyPass = "http://localhost:3000";
              extraConfig = ''
                rewrite ^/git(.*)$ $1 break;
              '';
            };
            "/invoices/" = {
              proxyPass = "http://10.0.0.2/";
            };
            "/atuin/" = {
              proxyPass = "http://127.0.0.1:8888";
            };
            "/vw/" = {
              proxyPass = "http://127.0.0.1:8222";
            };
          };
        };
      };
    };
    vaultwarden = {
      enable = true;
      #backupDir = "/home/goeranh/ssd/vaultwarden/backup";
      config = {
        DOMAIN = "https://${config.networking.fqdn}/vw";
        SIGNUPS_ALLOWED = true;
        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = 8222;
        ROCKET_LOG = "critical";
      };
    };
    # radicale = {
    #   enable = true;
    #   settings = {
    #     server.hosts = [ "127.0.0.1:5323" ];
    #     auth = {
    #       type = "htpasswd";
    #       htpasswd_filename = "/var/lib/radicale/htpasswd";
    #       # hash function used for passwords. May be `plain` if you don't want to hash the passwords
    #       htpasswd_encryption = "bcrypt";
    #     };
    #   };
    # };
  };

  containers = {
    invoiceplane = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "10.0.0.1";
      localAddress = "10.0.0.2";
      config = { config, pkgs, ... }: {

        nix.settings.experimental-features = [ "nix-command" "flakes" ];
        services.invoiceplane = {
          sites = {
            "10.0.0.2" = {
              enable = true;
              #port = 81;
              #proxyPathPrefix = "/invoices";
              database = {
                createLocally = true;
              };
            };
          };
        };

        system.stateVersion = "23.05";

        networking.firewall = {
          enable = true;
          allowedTCPPorts = [ 80 2222 ];
        };

        environment.etc."resolv.conf".text = "nameserver 8.8.8.8";
      };
    };
  };

  systemd = {
    services.nix-daemon.serviceConfig = {
      LimitNOFILE = lib.mkForce 8192;
      CPUWeight = 5;
      MemoryHigh = "4G";
      MemoryMax = "6G";
      MemorySwapMax = "0";
    };
    #network = {
    #  enable = true;
    #  networks."10-lan" = {
    #    enable = true;
    #    matchConfig.Name = "eth0";
    #    address = [ "192.168.178.2/24" ];
    #    gateway = [ "192.168.178.1" ];
    #    dns = [ "1.1.1.1" "9.9.9.9" ];
    #    routes = [
    #      { routeConfig.Gateway = "192.168.178.1"; }
    #      {
    #        routeConfig = {
    #          Gateway = "192.168.178.1";
    #          GatewayOnLink = true;
    #        };
    #      }
    #    ];
    #  };
    #};
  };

  system.stateVersion = "23.05"; # Did you read the comment?
}

