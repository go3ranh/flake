{ config, pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  goeranh = {
    server = true;
    update = true;
  };

  security = {
    sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };
  };
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "Europe/Berlin";

  users.users.goeranh = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    packages = with pkgs; [
    ];
  };

  networking = {
    hostName = "dockerhost";
    firewall.allowedTCPPorts = [ 22 80 443 ];
    defaultGateway = "10.0.0.1";
    useDHCP = false;
  };

  systemd = {
    network = {
      enable = true;
      networks = {
        ens18 = {
          matchConfig.Name = "ens18";
          address = [
            "10.0.0.132/24"
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


  environment.systemPackages = with pkgs; [
    vim
    git
    tmux
    wget
  ];

  virtualisation = {
    oci-containers = {
      containers = { };
    };
    docker = {
      enable = true;
    };
  };

  services.openssh.enable = true;
  services = {
    nginx = {
      enable = true;
      virtualHosts."10.0.0.132" = {
        default = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:2283";
        };
      };
      virtualHosts."${config.networking.fqdn}" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:2283";
        };
      };
    };
  };


  system.stateVersion = "23.11"; # Did you read the comment?

}
