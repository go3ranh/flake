{ self, config, lib, pkgs, ... }: {
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

  services = {
    openssh.enable = true;
    grafana = {
      enable = true;
      settings = {
        server = {
          domain = "${config.networking.fqdn}";
          http_port = 2342;
          http_addr = "127.0.0.1";
        };
      };
    };
    prometheus = {
      enable = true;
      port = 9001;
      exporters = {
        node = {
          enable = true;
          enabledCollectors = [ "systemd" ];
          port = 9002;
        };
      };

      scrapeConfigs = [
        {
          job_name = "local-scrape";
          static_configs = [{
            targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
          }];
        }
        {
          job_name = "nixfw-scrape";
          static_configs = [{
            targets = [ "10.0.0.1:9002" ];
          }];
        }
        {
          job_name = "workstation-scrape";
          static_configs = [{
            targets = [ "100.87.106.167:9002" ];
          }];
        }
      ];
    };
    loki = {
      enable = true;
      configuration = {
        server.http_listen_port = 3030;
        auth_enabled = false;

        ingester = {
          lifecycler = {
            address = "127.0.0.1";
            ring = {
              kvstore = {
                store = "inmemory";
              };
              replication_factor = 1;
            };
          };
          chunk_idle_period = "1h";
          max_chunk_age = "1h";
          chunk_target_size = 999999;
          chunk_retain_period = "30s";
          # max_transfer_retries = 0;
        };

        schema_config = {
          configs = [{
            from = "2022-06-06";
            store = "boltdb-shipper";
            object_store = "filesystem";
            schema = "v13";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }];
        };

        storage_config = {
          boltdb_shipper = {
            active_index_directory = "/var/lib/loki/boltdb-shipper-active";
            cache_location = "/var/lib/loki/boltdb-shipper-cache";
            cache_ttl = "24h";
          };

          filesystem = {
            directory = "/var/lib/loki/chunks";
          };
        };

        limits_config = {
          reject_old_samples = true;
          reject_old_samples_max_age = "168h";
          allow_structured_metadata = false;
        };

        chunk_store_config = {
          # max_look_back_period = "0s";
        };

        table_manager = {
          retention_deletes_enabled = false;
          retention_period = "0s";
        };

        compactor = {
          working_directory = "/var/lib/loki";
          # shared_store = "filesystem";
          compactor_ring = {
            kvstore = {
              store = "inmemory";
            };
          };
        };
      };
    };

    promtail = {
      enable = true;
      configuration = {
        server = {
          http_listen_port = 3031;
          grpc_listen_port = 0;
        };
        positions = {
          filename = "/tmp/positions.yaml";
        };
        clients = [{
          url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push";
        }];
        scrape_configs = [
          {
            job_name = "journal";
            journal = {
              max_age = "12h";
              labels = {
                job = "systemd-journal";
                host = "monitoring";
              };
            };
            relabel_configs = [{
              source_labels = [ "__journal__systemd_unit" ];
              target_label = "unit";
            }];
          }
        ];
      };
      # extraFlags
    };


    nginx.enable = true;
    nginx.virtualHosts.${config.services.grafana.settings.server.domain} = {
      forceSSL = true;
			enableACME = true;
      default = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header Host $host;
        '';
      };
    };

  };
  networking = {
    hostName = "monitoring";

    interfaces.ens18.ipv4.addresses = [{
      address = "10.0.0.26";
      prefixLength = 24;
    }];
    defaultGateway = "10.0.0.1";
    firewall.interfaces.ens18.allowedTCPPorts = [ 80 443 3030 ];
  };
}
