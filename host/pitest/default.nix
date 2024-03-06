{ config, pkgs, pkgs-unstable, lib, ... }:
let
  website = pkgs.stdenv.mkDerivation {
    pname = "website";
    version = "0.1";
    src = ./html;
    installPhase = ''
      			cp -r $src $out
      		'';
  };
in
{
  hardware.enableRedistributableFirmware = true;
  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";

  nixpkgs.config.packageOverrides = pkgs: {
    makeModulesClosure = x:
      # prevent kernel install fail due to missing modules
      pkgs.makeModulesClosure (x // { allowMissing = true; });
  };

  zramSwap = {
    enable = true;
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
  };

  networking = {
    hostName = "pitest"; # Define your hostname.
    nftables.enable = true;
    useDHCP = false;
    interfaces.eth0.ipv4.addresses = [
      {
        address = "192.168.178.2";
        prefixLength = 24;
      }
    ];
    defaultGateway = "192.168.178.1";
    nameservers = [ "1.1.1.1" "8.8.8.8" ];

    firewall = {
      enable = true;
      interfaces = {
        "tailscale0".allowedTCPPorts = [ 22 80 443 2222 ];
        "eth0".allowedTCPPorts = [ 22 80 443 2222 ];
      };
    };
    nat = {
      enable = true;
      internalInterfaces = [ "ve-+" ];
      externalInterface = "eth0";
      forwardPorts = [
        {
          sourcePort = 9090;
          proto = "tcp";
          destination = "10.10.0.3:9090";
        }
      ];
    };
  };

  nix = {
    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";
    settings = {
      builders-use-substitutes = true;
      cores = 4;
      #extra-platforms = "armv6l-linux";
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
    forgejo = {
      enable = true;
      settings = {
        service.DISABLE_REGISTRATION = true;
        server = {
          ROOT_URL = "https://${config.networking.fqdn}/git/";
          WORK_PATH = "/var/lib/forgejo";
          DISABLE_SSH = false;
          DOMAIN = "${config.networking.fqdn}";
          SSH_DOMAIN = "${config.networking.fqdn}";
          SSH_PORT = 2222;
          START_SSH_SERVER = true;
        };
        log.LEVEL = "Warn";
      };
      package = pkgs-unstable.forgejo;
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
              # todo
              root = "${website.outPath}";
            };
            "/git/" = {
              proxyPass = "http://localhost:3000";
              extraConfig = ''
                rewrite ^/git(.*)$ $1 break;
              '';
            };
            "/invoices/" = {
              proxyPass = "http://10.10.0.2/";
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
  };

  containers = {
    invoiceplane = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "10.10.0.1";
      localAddress = "10.10.0.2";
      config = { config, pkgs, ... }: {

        services.invoiceplane = {
          sites = {
            "10.10.0.2" = {
              enable = true;
              #port = 81;
              #proxyPathPrefix = "/invoices";
              database = {
                createLocally = true;
              };
            };
          };
        };

        system.stateVersion = "23.11";

        networking.firewall = {
          enable = true;
          allowedTCPPorts = [ 80 2222 ];
        };

        environment.etc."resolv.conf".text = "nameserver 8.8.8.8";
      };
    };
    ntfy = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "10.10.0.1";
      localAddress = "10.10.0.3";
      config = { config, pkgs, ... }: {

        services.ntfy-sh = {
          enable = true;
          settings = {
            listen-http = ":9090";
            base-url = "http://192.168.178.2:9090";
          };
        };

        system.stateVersion = "23.11";

        networking.firewall = {
          enable = true;
          allowedTCPPorts = [ 9090 ];
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
  };

  system.stateVersion = "23.11"; # Did you read the comment?
}

