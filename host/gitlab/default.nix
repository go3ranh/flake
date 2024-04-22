{ self, config, lib, pkgs, ... }:{
	disko.devices = {
  disk = {
   my-disk = {
    device = "/dev/sda";
    type = "disk";
    content = {
     type = "gpt";
     partitions = {
      ESP = {
       type = "EF00";
       size = "500M";
       content = {
        type = "filesystem";
        format = "vfat";
        mountpoint = "/boot";
       };
      };
      root = {
       size = "100%";
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

	services.openssh.enable = true;
	networking = {
		hostName = "gitlab";

		interfaces.ens18.ipv4.addresses = [{
			address = "10.0.0.21";
			prefixLenght = 24;
		}];
		defaultGateway = "10.0.0.1";
	};
};
