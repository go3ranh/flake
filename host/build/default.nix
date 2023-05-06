{ inputs, config, pkgs, ... }:
let
  hostname = "nixbuild";
  domainname = "tailf0ec0.ts.net";
in
{
  imports =
    [
      ./hardware-configuration.nix
    ];


  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "${hostname}";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  environment.systemPackages = with pkgs; [
    vim
    zellij
    tmux
    htop
    wget
	gcc
	cargo
	rustc
  ];

  virtualisation.docker.enable = true;
  services = {
    openssh = {
      enable = true;
    };
    tailscale = {
      enable = true;
    };
    hydra = {
      enable = true;
      hydraURL = "https://${hostname}.${domainname}/";
      port = 3001;
      useSubstitutes = true;
      notificationSender = "goeran@karsdorf.net";
    };
    postgresql = {
      package = pkgs.postgresql_15;
      enable = true;
      ensureUsers = [
        {
          name = "hydra";
          ensurePermissions = {
            "DATABASE hydra" = "ALL PRIVILEGES";
          };
        }
      ];
      ensureDatabases = [
        "hydra"
      ];
    };
    nginx = {
      enable = true;
      virtualHosts = {
        "${hostname}.${domainname}" = {
          sslCertificate = "/var/lib/nixhost.tailf0ec0.ts.net.crt";
          sslCertificateKey = "/var/lib/nixhost.tailf0ec0.ts.net.key";
          forceSSL = true;
          locations = {
            "/" = {
              recommendedProxySettings = true;
              proxyPass = "http://localhost:3001";
            };
          };
        };
      };
    };
  };

  programs = {
    git = {
      enable = true;
    };

    neovim = {
      enable = true;
    };
  };

  networking.firewall.allowedTCPPorts = [ 22 80 443 ];

  system.stateVersion = "22.11"; # Did you read the comment?
}
