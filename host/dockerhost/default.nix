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
    interfaces.ens18.ipv4.addresses = [{
      address = "10.0.0.132";
      prefixLength = 24;
    }];
    defaultGateway = "10.0.0.1";
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
        sslCertificate = "/var/lib/${config.networking.fqdn}.cert.pem";
        sslCertificateKey = "/var/lib/${config.networking.fqdn}.key.pem";
        extraConfig = ''
          					ssl_password_file /var/lib/${config.networking.fqdn}.pass;
          				'';
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:2283";
        };
      };
    };
  };


  system.stateVersion = "23.11"; # Did you read the comment?

}
