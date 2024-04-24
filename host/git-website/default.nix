{ self, config, lib, pkgs, ... }:{
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
 #    "/".device = lib.mkForce "/dev/sda2";
 #    "/boot".device = lib.mkForce "/dev/sda1";
 #  };

	services = {
		openssh.enable = true;
		nginx = {
      enable = true;
      virtualHosts = {
        "${config.networking.fqdn}" = {
          sslCertificate = "/var/lib/${config.networking.fqdn}.cert.pem";
          sslCertificateKey = "/var/lib/${config.networking.fqdn}.key.pem";
          extraConfig = ''
						ssl_password_file /var/lib/${config.networking.fqdn}.pass;
					'';
          forceSSL = true;
					default = true;
          locations = {
            "/" = 
						let
						  website = pkgs.fetchFromGitLab {
								owner = "MLpGitLab";
								repo = "website-fakfestIM";
								rev = "04683610b6d38906315f314d0f16d5d5aad4274b";
								hash = "sha256-gUaJuJjCabncOt6Blb1XFvD2PhLsN+XyHpXUHZTqoik=";
							};
						in{
              # todo
              root = "${website.outPath}";
            };
          };
        };
      };
		};
	};
	networking = {
		hostName = "git-website";

		interfaces.ens18.ipv4.addresses = [{
			address = "10.0.0.23";
			prefixLength = 24;
		}];
		defaultGateway = "10.0.0.1";
		firewall.interfaces.ens18.allowedTCPPorts = [ 80 443 ];
	};
}
