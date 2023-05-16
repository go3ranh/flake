{ config, pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
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

  goeranh = {
    development = true;
  };

  security.sudo.extraRules = [
    {
      users = [ "goeranh" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ]; # "SETENV" # Adding the following could be a good idea
        }
      ];
    }
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
    seatd
    pciutils
    kitty
    gnome-console
    firefox
  ];

  programs.hyprland = {
    enable = true;
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
    ];
  };

  security.polkit.enable = true;

  services = {
    dbus = {
      enable = true;
    };
    openssh = {
      enable = true;
      extraConfig = ''
        MaxAuthTries 16
      '';
    };
    greetd = {
      enable = true;
      package = pkgs.tuigreet;
      settings = {
        default_session =
          let
            hyprConfig = pkgs.writeText "greetd-hyprland-config" ''
              exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
              exec-once = ${pkgs.waybar}/bin/waybar
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
              bind = SUPER, Return, exec, ${pkgs.kitty}/bin/kitty
              bind = SUPER, D, exec, ${pkgs.wofi}/bin/wofi --show drun -I -m -i
              bind = SUPER, 1, workspace, 1
              bind = SUPER, 2, workspace, 2
              bind = SUPER, 3, workspace, 3
              bind = SUPER, 4, workspace, 4
              bind = SUPER, 5, workspace, 5
              bind = SUPER, 6, workspace, 6
              bind = SUPER, 7, workspace, 7
              bind = SUPER, 8, workspace, 8
              bind = SUPER, 9, workspace, 9
              bind = SUPER, 0, workspace, 10
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
  };

  system.stateVersion = "22.11"; # Did you read the comment?

}
