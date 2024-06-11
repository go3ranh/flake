{ self, config, lib, pkgs, ... }: {
  sops = {
    # This will automatically import SSH keys as age keys
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = ./secrets.yaml;
    defaultSopsFormat = "yaml";
    secrets = {
      "dbpass" = {
        owner = "nextcloud";
        group = "nextcloud";
        mode = "0440";
      };
    };
  };
  disko.devices = {
    disk = {
      sda = {
        device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0";
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
  fileSystems = {
    "/".device = lib.mkForce "/dev/sda2";
    "/boot".device = lib.mkForce "/dev/sda1";
  };

  services = {
    openssh.enable = true;
    nginx = {
      enable = true;

			recommendedGzipSettings = true;
			recommendedOptimisation = true;
			recommendedProxySettings = true;
			recommendedTlsSettings = true;

      virtualHosts."${config.networking.fqdn}" = {
        enableACME = true;
        default = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost";
        };
      };
    };
		nextcloud = {
			enable = false;
			hostName = "${config.networking.fqdn}";
			#nginx.enable = true;
			https = true;
			autoUpdateApps.enable = true;
			autoUpdateApps.startAt = "05:00:00";

			settings = {
				overwriteProtocol = "https";
			};
			config = {
				dbtype = "pgsql";
				dbuser = "nextcloud";
				dbhost = "/run/postgresql"; # nextcloud will add /.s.PGSQL.5432 by itself
				dbname = "nextcloud";
				dbpassFile = "/var/nextcloud-db-pass";

				adminpassFile = "/var/nextcloud-admin-pass";
				adminuser = "admin";
			};
		};

  };
  networking = {
    hostName = "nextcloud";
    useDHCP = false;
    firewall.allowedTCPPorts = [ 22 80 443 ];

    interfaces.ens18.ipv4.addresses = [{
      address = "10.0.0.33";
      prefixLength = 24;
    }];
    defaultGateway = "10.0.0.1";
    nftables = {
      # tables = {
      # 	filter = {
      # 		family = "inet";
      # 		enable = true;
      # 		content = ''
      #       chain input {
      #         type filter hook input priority 0;
      #         iifname lo accept
      #         ct state vmap { established : accept, related : accept, invalid : drop }

      #         ip saddr { 10.0.0.0/23, 10.200.0.0/24 } ip protocol icmp icmp type { destination-unreachable, router-advertisement, time-exceeded, parameter-problem, echo-request } counter accept
      #         ip saddr { 10.0.0.0/23, 10.200.0.0/24 } tcp dport { 22, 80, 443 } counter accept
      # 				drop
      #       }
      # 		'';
      # 	};
      # };
    };
  };
}
