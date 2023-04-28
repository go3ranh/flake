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

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

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

  # Configure keymap in X11
  services.xserver = {
    layout = "de";
    xkbVariant = "";
  };

  # Configure console keymap
  console.keyMap = "de";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.goeranh = {
    isNormalUser = true;
    description = "Goeran Heinemann";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = with pkgs; [ ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim
    zellij
    tmux
    htop
    wget
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
      hydraURL = "https://${hostname}.${domainname}";
      notificationSender = "build@goeran";
      useSubstitutes = true;
      listenHost = "*";
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
          default = true;
          sslCertificate = "/var/lib/nixbuild.tailf0ec0.ts.net.crt";
          sslCertificateKey = "/var/lib/nixbuild.tailf0ec0.ts.net.key";
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString config.services.hydra.port}";
            recommendedProxySettings = true;
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
  networking.firewall.enable = true;

  system.stateVersion = "22.11"; # Did you read the comment?
}
