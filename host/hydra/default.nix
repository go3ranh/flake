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
      "attic-secret-key" = {
        owner = "${config.services.atticd.user}";
        group = "${config.services.atticd.group}";
        mode = "0440";
      };
    };
  };
	users.users.atticd = {
		isSystemUser = true;
		group = "atticd";
	};
	users.groups.atticd = {};
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

	nix = {
		buildMachines = [
			{
				hostName = "localhost";
				maxJobs = 1;
				speedFactor = 2;
				systems = [
					"x86_64-linux"
					"aarch64-linux"
				];

				supportedFeatures = [
					 # "kvm"
					 # "nixos-test"
					"big-parallel"
					"benchmark"
				];
			}
		];
		settings = {
			allowed-uris = [
				"github:NixOS/nixpkgs/"
				"github:Mic92/sops-nix/"
				"github:nix-community/"
				"github:numtide/flake-utils/"
				"github:nix-systems/default/"
				"github:zhaofengli/attic/"
				"github:ipetkov/crane/"
			];
			allowed-users = [
				"@wheel"
				"@builders"
				"goeranh"
				"hydra"
				"hydra-queue-runner"
				"hydra-www"
			];
		};
	};
  services = {
    openssh.enable = true;
    nix-serve = {
      enable = true;
      secretKeyFile = "/run/secrets/cache-key";
    };
		postgresql = {
      enable = true;
      enableJIT = true;
      identMap = ''
        # ArbitraryMapName systemUser DBUser
           superuser_map      root      postgres
           superuser_map      goeranh		postgres
           # Let other names login as themselves
           # superuser_map      /^(.*)$   \1
      '';

      ensureDatabases = [ "atticd" ];
      ensureUsers = [
        {
          name = "atticd";
          ensureDBOwnership = true;
        }
      ];

      # upgrade = {
      #   enable = true;
      #   stopServices = [
      #     "hydra-evaluator"
      #     "hydra-init"
      #     "hydra-notify"
      #     "hydra-queue-runner"
      #     "hydra-send-stats"
      #     "hydra-server"
      #     "atticd"
      #   ];
      # };
    };

    hydra = {
      enable = true;
      useSubstitutes = true;
      notificationSender = "notify@hydra.${config.networking.domain}";
      minimumDiskFree = 5;
      minimumDiskFreeEvaluator = 10;
      listenHost = "*";
      hydraURL = "https://${config.networking.fqdn}";
			extraConfig =
        let
          key = config.sops.secrets."cache-key".path;
        in
        ''
          # binary_cache_secret_key_file = ${key}
          compress_num_threads = 4
          evaluator_workers = 4
          evaluator_max_memory_size = 2048
          max_output_size = ${toString (5*1024*1024*1024)} # sd card and raw images
          store_uri = auto?secret-key=${key}&write-nar-listing=1&ls-compression=zstd&log-compression=zstd
          upload_logs_to_binary_cache = true
        '';
    };
		atticd = {
      enable = true;

      credentialsFile = config.sops.secrets."attic-secret-key".path;

      settings = {
        listen = "127.0.0.1:8183";
        allowed-hosts = [ "attic.${config.networking.domain}" ];
        api-endpoint = "https://attic.${config.networking.domain}";
        # compression.type = "none"; # let ZFS do the compressing
        database = {
          url = "postgres://atticd?host=/run/postgresql";
          heartbeat = true;
        };
        # storage = {
        #   type = "local";
        #   path = "/ZFS/ZFS-primary/attic/storage";
        # };

        # Warning: If you change any of the values here, it will be
        # difficult to reuse existing chunks for newly-uploaded NARs
        # since the cutpoints will be different. As a result, the
        # deduplication ratio will suffer for a while after the change.
        chunking = {
          # The minimum NAR size to trigger chunking
          #
          # If 0, chunking is disabled entirely for newly-uploaded NARs.
          # If 1, all NARs are chunked.
          nar-size-threshold = 64 * 1024; # 64 KiB
          # The preferred minimum size of a chunk, in bytes
          min-size = 16 * 1024; # 16 KiB
          # The preferred average size of a chunk, in bytes
          avg-size = 64 * 1024; # 64 KiB
          # The preferred maximum size of a chunk, in bytes
          max-size = 256 * 1024; # 256 KiB
        };
      };
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
      virtualHosts."attic.${config.networking.domain}" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:8183/";
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
