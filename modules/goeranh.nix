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
    hypr = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = "install hyprland";
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
      pciutils
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


    #environment.systemPackages = with pkgs; [
    #  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  #  wget
    #  seatd
    #  pciutils
    #  kitty
    #  gnome-console
    #  firefox
    #];

    programs.hyprland = mkIf cfg.hypr {
      enable = true;
    };

    xdg.portal = mkIf cfg.hypr {
      enable = true;
      wlr.enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-wlr
      ];
    };

    security.polkit.enable = mkIf cfg.hypr true;

    services.dbus = mkIf cfg.hypr {
      enable = true;
    };
    services.greetd = mkIf cfg.hypr {
      enable = true;
      package = pkgs.tuigreet;
      settings = {
        default_session =
          let
            hyprConfig = pkgs.writeText "greetd-hyprland-config" ''
              exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
              exec-once = ${pkgs.waybar}/bin/waybar

              monitor=eDP-1,1920x1200@60,0x0,1

              input {
                kb_layout = de
                follow_mouse = 1
                sensitivity = 0 # -1.0 - 1.0, 0 means no modification.
              }
              animations {
                enabled = false
              }
              general {
                gaps_in=5
                gaps_out=5
                border_size=1
                col.active_border=0xff7D4045
                col.inactive_border=0xff382D2E
                no_border_on_floating = false
                layout = dwindle
                no_cursor_warps = true
              }
			  $mainMod = SUPER
              bind = $mainMod, Return, exec, ${pkgs.kitty}/bin/kitty
              bind = $mainMod, D, exec, ${pkgs.wofi}/bin/wofi --show drun -I -m -i
			  bind = SUPERSHIFT, Q, killactive,
              bind = SUPERALT, E, exit,
			  bind = $mainMod, V, togglefloating,

              bind = $mainMod, 1, workspace, 1
              bind = $mainMod, 2, workspace, 2
              bind = $mainMod, 3, workspace, 3
              bind = $mainMod, 4, workspace, 4
              bind = $mainMod, 5, workspace, 5
              bind = $mainMod, 6, workspace, 6
              bind = $mainMod, 7, workspace, 7
              bind = $mainMod, 8, workspace, 8
              bind = $mainMod, 9, workspace, 9
              bind = $mainMod, 0, workspace, 10
            '';
            hyprLaunch = pkgs.writeShellScriptBin "hyprland-launcher" ''
              #!/bin/sh
              export WLR_RENDERER_ALLOW_SOFTWARE=1
              exec ${pkgs.hyprland.outPath}/bin/Hyprland --config ${hyprConfig}
            '';
          in
          {
            command = "${pkgs.greetd.tuigreet}/bin/tuigreet --cmd ${hyprLaunch}/bin/hyprland-launcher";
            user = "greeter";
          };
      };
    };

    nixpkgs.config.allowUnfree = true;
    networking.firewall.enable = true;

    console.keyMap = "de";

    services.tailscale.enable = true;
  };
}
