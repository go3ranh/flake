{ inputs, config, pkgs, lib, ... }:
with lib;
let
  cfg = config.goeranh;
in
{
  options.goeranh = {
    desktop = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = "install gnome desktop witch customizations";
    };
    development = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = "install my dev tools";
    };
    gaming = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = "install steam, etc";
    };
  };
  config = {
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    users.users.goeranh = {
      isNormalUser = true;
      extraGroups = [ "wheel" "libvirtd" "docker" "networkmanager" "dialout" ];
      openssh.authorizedKeys.keys = [
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBHaU3idFwbk0uY4jooS9dwdBvNLnWfgFRmc7hkSeubSAWnT5J6NM8L8NZrT1ZoiYfebsKmwIn111BGfohZkC6wA= homelab key goeranh"
      ];
      packages = builtins.concatLists [
        (with pkgs; [
          btrfs-progs
          tailscale
        ])
        (if cfg.desktop then with pkgs; [
          bitwarden
          chromium
          dbeaver
          discord
          filezilla
          firefox
          gajim
          gnome3.gnome-terminal
          libreoffice
          okular
          poppler_utils
          quickemu
          rambox
          shotwell
          signal-desktop
          spotify
          thunderbird
          vieb
          virt-manager
          virt-viewer
          vlc
        ] else [ ])
        (if cfg.development then with pkgs; [
          ghidra
          gitkraken
          gnome-builder
          jetbrains.idea-community
          jetbrains.webstorm
          jetbrains.phpstorm
          jetbrains.jdk
          libxcrypt
          meson
          ninja
          nodejs
        ] else [ ])
        (if cfg.gaming then with pkgs; [
          lutris
          wine
          wine-wayland
        ] else [ ])
      ];
    };

    programs = {
      steam = mkIf cfg.gaming {
        enable = true;
        remotePlay.openFirewall = true;
      };
	  bash = {
		enableCompletion = true;
	  };
    };


    environment.systemPackages = with pkgs; [
      bash
      bat
      direnv
      exa
      fzf
      gettext
      git
      gitui
      gnupg
      gofu
      htop
      neovim
      nix-direnv
      nmap
      ripgrep
      tmux
      unzip
      wget
      zellij
    ];

    environment.gnome.excludePackages = mkIf cfg.desktop [
      pkgs.gnome.baobab # disk usage analyzer
      pkgs.gnome.cheese # photo booth
      #eog         # image viewer
      #epiphany    # web browser
      pkgs.gnome.gedit # text editor
      pkgs.gnome.simple-scan # document scanner
      #totem       # video player
      pkgs.gnome.yelp # help viewer
      pkgs.gnome.evince # document viewer
      pkgs.gnome.geary # email client

      # these should be self explanatory
      pkgs.gnome.gnome-calculator
      pkgs.gnome.gnome-calendar
      pkgs.gnome.gnome-clocks
      pkgs.gnome.gnome-contacts
      pkgs.gnome.gnome-font-viewer
      pkgs.gnome.gnome-logs
      pkgs.gnome.gnome-maps
      pkgs.gnome.gnome-music
      pkgs.gnome.gnome-weather
      pkgs.gnome-connections
    ];
    services.xserver = mkIf cfg.desktop {
      enable = true;
      displayManager.gdm.enable = true;
      displayManager.gdm.wayland = true;
      desktopManager.gnome.enable = true;
      layout = "de";
      xkbVariant = "";
    };
    nixpkgs.config.allowUnfree = true;
    networking.firewall.enable = true;

    console.keyMap = "de";

    services.tailscale.enable = true;
  };
}
