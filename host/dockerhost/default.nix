{ config, pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  goeranh = {
    server = true;
    #trust-builder = true;
    update = true;
  };

  security = {
    sudo = {
      enable = true;
      # wheelNeedsPassword = false;
      extraRules = [{
        commands = [
          {
            command = "${pkgs.nixos-rebuild}/bin/nixos-rebuild switch";
            options = [ "NOPASSWD" ];
          }
        ];
        groups = [ "wheel" ];
      }];
    };
  };
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkbOptions in tty.
  # };

  users.users.goeranh = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    packages = with pkgs; [
    ];
  };

  networking = {
    hostName = "dockerhost";
    firewall.allowedTCPPorts = [ 22 80 ];
    nameservers = [ "1.1.1.1" ];
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
    docker-compose
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
        locations."/" = {
          proxyPass = "http://127.0.0.1:2283";
        };
      };
    };
  };


  system.stateVersion = "23.11"; # Did you read the comment?

}
