{ config, pkgs, lib, ... }:

{
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  fileSystems."/" =
    {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };


  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    initrd = {
      availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
      kernelModules = [ ];
    };
    kernelModules = [ ];
    extraModulePackages = [ ];
  };

  networking = {
    hostName = "nixfw";
    interfaces = {
      ens18.ipv4.addresses = [{
        address = "10.16.23.95";
        prefixLength = 21;
      }];
      ens19.ipv4.addresses = [{
        address = "10.0.0.1";
        prefixLength = 24;
      }];
    };
    defaultGateway = "10.16.23.1";
    nameservers = [ "1.1.1.1" ];
    nftables = {
      enable = true;
      ruleset = ''
        table ip nat {
          chain PREROUTING {
            type nat hook prerouting priority dstnat; policy accept;
          }
        }
      '';
    };
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 53 ];
      allowedUDPPorts = [ 53 ];
    };
    nat = {
      enable = true;
      internalInterfaces = [ "ens19" ];
      externalInterface = "ens18";
      forwardPorts = [
      ];
    };
  };
  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "en_US.UTF-8";

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };
  goeranh = {
    server = true;
    trust-builder = false;
    remote-store = false;
  };

  services = {
    bind = {
      enable = true;
      zones = {
        "netbird.selfhosted" =
          let
            zonefile = pkgs.writeText "zone" ''
              $ORIGIN netbird.selfhosted.
              $TTL 3600
              netbird.selfhosted.  IN  SOA   nixfw.netbird.selfhosted. goeranh.netbird.selfhosted. ( 2020091025 7200 3600 1209600 3600 )
              netbird.selfhosted.  IN  NS    nixfw

              onlyoffice.kbuild  IN  CNAME kbuild
              kbuild             IN  A     100.87.25.209
              pitest             IN  A     100.87.123.127
              nixfw              IN  A     100.87.17.62
              dockerhost         IN  A     10.0.0.132
              node5              IN  A     100.87.55.241
              server-gitea       IN  A     100.87.18.24
              workstation        IN  A     100.87.106.167
              oraclearm          IN  A     100.87.250.85
              					'';
          in
          {
            master = true;
            file = "${zonefile}";
          };
      };
			extraOptions = ''
			recursion yes;
			allow-recursion { any; };
			'';
    };
  };

  system.stateVersion = "23.11";
}

