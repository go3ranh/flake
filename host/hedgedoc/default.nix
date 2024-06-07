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
  # fileSystems = {
  #   "/".device = lib.mkForce "/dev/sda2";
  #   "/boot".device = lib.mkForce "/dev/sda1";
  # };

  services = {
    openssh.enable = true;
    nginx = {
      enable = false;
      virtualHosts."${config.networking.fqdn}" = {
        enableACME = true;
        default = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://unix:${config.services.forgejo.settings.server.HTTP_ADDR}";
        };
      };
      # virtualHosts."hound.${config.networking.domain}" = {
      #   enableACME = true;
      #   default = true;
      #   forceSSL = true;
      #   locations."/" = {
      #     proxyPass = "http://unix:${config.services.forgejo.settings.server.HTTP_ADDR}";
      #   };
      # };
    };
    hedgedoc = {
      enable = true;
      settings = {
        allowAnonymousEdits = true;
        allowEmailRegister = true;
        allowFreeURL = true;
        allowOrigin = [ "${config.networking.fqdn}" ];
        csp = {
          enable = true;
          addDefaults = true;
          upgradeInsecureRequest = "auto";
        };
        # db = {
        #   dialect = "postgres";
        #   host = "/run/postgresql/";
        # };
        defaultPermission = "freely";
        domain = "${config.networking.fqdn}";
        email = false; # only allow ldap login
        loglevel = "warn";
        path = "/run/hedgedoc/hedgedoc.sock";
        protocolUseSSL = true;
        sessionSecret = "$sessionSecret";
      };
      #environmentFile = config.sops.secrets."hedgedoc".path;
    };
  };
  networking = {
    hostName = "hedgedoc";
    useDHCP = false;
    firewall.allowedTCPPorts = [ 22 80 443 ];

    interfaces.ens18.ipv4.addresses = [{
      address = "10.0.0.31";
      prefixLength = 24;
    }];
    defaultGateway = "10.0.0.1";
  };
}
