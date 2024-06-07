{ inputs, config, pkgs, lib, ... }:
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
    update = true;
    monitoring = false;
  };

  networking = {
    hostName = "pitest"; # Define your hostname.
    nftables.enable = true;
    useDHCP = false;
    firewall = {
      enable = true;
      interfaces = {
        "wt0".allowedTCPPorts = [ 22 80 443 2222 ];
        "wg0".allowedTCPPorts = [ 22 80 443 2222 ];
        "eth0".allowedTCPPorts = [ 22 ];
      };
    };

    nat = {
      enable = true;
      internalInterfaces = [ "br0" ];
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
      package = pkgs.forgejo;
    };
    nginx = {
      enable = true;
      virtualHosts = {
        "${config.networking.hostName}" = {
          globalRedirect = "${config.networking.fqdn}";
        };
        "${config.networking.fqdn}" = {
          sslCertificate = "/var/lib/${config.networking.fqdn}.cert.pem";
          sslCertificateKey = "/var/lib/${config.networking.fqdn}.key.pem";
          extraConfig = ''
            					  ssl_password_file /var/lib/pitest.netbird.selfhosted.pass;
            					'';
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
      hostBridge = "br0";
      localAddress = "10.10.0.2/24";
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

        networking = {
          defaultGateway.address = "10.10.0.1";
          firewall = {
            enable = true;
            allowedTCPPorts = [ 80 2222 ];
          };
        };

        environment.etc."resolv.conf".text = "nameserver 8.8.8.8";
      };
    };
  };

  systemd = {
    network = {
      enable = true;
      netdevs = {
        "10-wg0" = {
          netdevConfig = {
            Kind = "wireguard";
            Name = "wg0";
            MTUBytes = "1300";
          };
          wireguardConfig = {
            PrivateKeyFile = "/var/lib/wireguard/private";
            ListenPort = 9918;
          };
          wireguardPeers = [
            {
              PublicKey = "fvGBgD6oOqtcgbbLXDRptL1QomkSlKh29I9EhYQx1iw=";
              AllowedIPs = [ "10.200.0.0/24" "10.0.0.0/24" "10.0.1.0/24" ];
              Endpoint = "49.13.134.146:51820";
              PersistentKeepalive = 30;
            }
          ];
        };
        "20-br0" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "br0";
          };
        };
      };
      networks = {
        eth0 = {
          matchConfig.Name = "eth0";
          address = [
            "192.168.178.2/24"
          ];
          DHCP = "no";
          gateway = [
            "192.168.178.1"
          ];
          networkConfig = {
            IPv6AcceptRA = false;
          };
        };
        wg0 = {
          matchConfig.Name = "wg0";
          address = [
            "10.200.0.4/24"
          ];
          DHCP = "no";
          routes = [
            {
              Gateway = "10.200.0.5";
              Destination = "10.0.0.0/24";
            }
            {
              Gateway = "10.200.0.5";
              Destination = "10.0.1.0/24";
            }
          ];
          networkConfig = {
            IPv6AcceptRA = false;
          };
        };
        "40-br0" = {
          matchConfig.Name = "br0";
          bridgeConfig = { };
          networkConfig.LinkLocalAddressing = "no";
          address = [
            "10.10.0.1/24"
          ];
          networkConfig = {
            ConfigureWithoutCarrier = true;
          };
        };
      };
    };
    services = {
      nix-daemon.serviceConfig = {
        LimitNOFILE = lib.mkForce 8192;
        CPUWeight = 5;
        MemoryHigh = "4G";
        MemoryMax = "6G";
        MemorySwapMax = "0";
      };
      btrfs-copy-snap = {
        path = with pkgs; [
          btrfs-progs
        ];
        script = ''
          				  cp -r /var/lib/forgejo/ /home/goeranh/ssd/backups
          				  cp -r /var/lib/nixos-containers/invoiceplane/ /home/goeranh/ssd/backups
          				  cp -r /var/lib/bitwarden_rs/ /home/goeranh/ssd/backups
          					cd /home/goeranh/ssd
          					btrfs subvolume snapshot backups backups-$(date "+%Y-%m-%d-%H:%M")
          				'';

        startAt = "daily";
      };
    };
  };

  system.stateVersion = "23.11"; # Did you read the comment?
}

