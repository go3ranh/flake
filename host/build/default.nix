{ inputs, config, pkgs, ... }:
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

  networking.hostName = "nixbuild";
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
	  hydraURL = "http://nixbuild";
	};
	nginx = {
	  enable = true;
	  virtualHosts = {
	    "nixbuild" = {
		  default = true;
		  locations."/".proxyPass = "http://127.0.0.1:${toString config.services.hydra.port}";
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
