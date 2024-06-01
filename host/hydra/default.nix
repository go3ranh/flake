{ config, pkgs, ... }:
{
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  sops = {
    # This will automatically import SSH keys as age keys
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = ./secrets.yaml;
    defaultSopsFormat = "yaml";
    secrets = {
      "cache-key" = {
        owner = "hydra";
        group = "hydra";
        mode = "0440";
      };
    };
  };
  security = {
    sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };
  };
  networking = {
    hostName = "hydra";
    firewall.allowedTCPPorts = [ 22 80 443 ];
    defaultGateway = "10.0.0.1";
    useDHCP = false;
    hostId = "e679682b";
  };

  systemd = {
    network = {
      enable = true;
      networks = {
        ens18 = {
          matchConfig.Name = "ens18";
          address = [
            "10.0.0.30/24"
          ];
          DHCP = "no";
          gateway = [
            "10.0.0.1"
          ];
          networkConfig = {
            IPv6AcceptRA = true;
          };
        };
      };
    };
  };

	nix.settings = {
		allowed-uris = [
			"github:NixOS/nixpkgs/"
			"github:Mic92/sops-nix/"
			"github:nix-community/"
			"github:numtide/flake-utils/"
			"github:nix-systems/default/"
		];
		allowed-users = [
			"goeranh"
			"hydra"
		];
	};
  services = {
    openssh.enable = true;
    nix-serve = {
      enable = true;
      secretKeyFile = "/run/secrets/cache-key";
    };
    hydra = {
      enable = true;
      useSubstitutes = true;
      notificationSender = "notify@hydra.goeranh.selfhosted";
      minimumDiskFree = 5;
      minimumDiskFreeEvaluator = 10;
      listenHost = "*";
      hydraURL = "https://${config.networking.fqdn}";
			extraConfig =
        let
          key = config.sops.secrets."cache-key".path;
        in
        ''
          binary_cache_secret_key_file = ${key}
          compress_num_threads = 4
          evaluator_workers = 4
          evaluator_max_memory_size = 2048
          max_output_size = ${toString (5*1024*1024*1024)} # sd card and raw images
          # store_uri = auto?secret-key=${key}&write-nar-listing=1&ls-compression=zstd&log-compression=zstd
          upload_logs_to_binary_cache = true
        '';
    };
    nginx = {
      enable = true;
      virtualHosts."${config.networking.fqdn}" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:3000/";
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
      };
    };
  };
  disko.devices = {
    disk = {
      sda = {
        device = "/dev/sda";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "500M";
              name = "ESP";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              name = "nixos";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
  goeranh = {
    server = true;
    update = true;
  };
}
