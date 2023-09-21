{ inputs, config, pkgs, lib, ... }:
with lib;
let
  cfg = config.goeranh;
  kanshiConfig = pkgs.writeText "kanshi-config" ''
    profile docked{
    	#output "Sharp Corporation 0x14F9 " disable
    	#output "AOC 2460G4 0x00007D1E " mode 1920x1080 position 0,0
    	#output "Dell Inc. DELL U2414H 292K478E03ML " mode 1920x1080 position 1920,0
    	output eDP-1 disable
    	output DP-5 mode 1920x1080 position 0,0
    	output DP-6 mode 1920x1080 position 1920,0
    }
    
    profile laptop{
    	output eDP-1 mode 1920x1200 position 0,0 scale 1
    }
    
    profile stura1{
    	output eDP-1 mode 1920x1200 position 0,1080 scale 1
    	output DP-1 mode 1920x1080 position 0,0 scale 1
    }
    
    profile stura2{
    	output eDP-1 mode 1920x1200 position 0,1080 scale 1
    	output DP-5 mode 1920x1080 position 0,0 scale 1
    }
  '';
in
{
  options.goeranh = {
    desktop = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = "install gnome desktop witch customizations";
    };
    server = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = "apply server settings";
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
    nix = {
      settings = {
        experimental-features = [ "nix-command" "flakes" ];
        auto-optimise-store = true;
      };
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
    };
    users.users.goeranh = {
      isNormalUser = true;
      extraGroups = [ "wheel" "libvirtd" "docker" "networkmanager" "dialout" "plugdev" ];
      openssh.authorizedKeys.keys = mkIf cfg.server [
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBHaU3idFwbk0uY4jooS9dwdBvNLnWfgFRmc7hkSeubSAWnT5J6NM8L8NZrT1ZoiYfebsKmwIn111BGfohZkC6wA= homelab key goeranh"
      ];
      packages = builtins.concatLists [
        (with pkgs; [
          atuin
          btrfs-progs
          dig
          rsync
          tailscale
        ])
        (if cfg.desktop || cfg.hypr then with pkgs; [
          #bitwarden # nodejs 16 deprecated
          chromium
          dbeaver
          discord
          filezilla
          firefox
          gajim
          gnome3.gnome-terminal
          gpa
          libreoffice
          logseq
          obsidian
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
          binwalk
          file
          ghidra
          gitkraken
          gnome-builder
          jetbrains.idea-community
          jetbrains.jdk
          jetbrains.phpstorm
          jetbrains.webstorm
          jetbrains.clion
          libxcrypt
          meson
          gnumake
          cmake
          ninja
          nodejs
        ] else [ ])
        (if cfg.hypr then with pkgs; [
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
        shellInit = ''
          alias nrepl="nix repl --file /etc/nixos/repl.nix"
        '';
      };
      tmux = {
        enable = true;
        terminal = "screen-256color";
        keyMode = "vi";
        historyLimit = 50000;
        escapeTime = 50;
        baseIndex = 1;
        plugins = with pkgs.tmuxPlugins; [
          sidebar # prefix + tab / backspace
          fingers # quick copy paste prefix + f
        ];
        extraConfig = ''
          bind '§' splitw -hc '#{pane_current_path}'
          bind -n M-z resize-pane -Z
          #open copy mode y
          bind y copy-mode
          #vi scrolling
          set-window-option -g mode-keys vi
          #u/f pageup/pagedown
          bind -T copy-mode u send -X page-up
          bind -T copy-mode f send -X page-down

          bind -n M-h select-pane -L
          bind -n M-l select-pane -R
          bind -n M-k select-pane -U
          bind -n M-j select-pane -D
          bind -n M-H select-pane -L
          bind -n M-L select-pane -R
          bind -n M-K select-pane -U
          bind -n M-J select-pane -D
          bind h select-pane -L
          bind j select-pane -D
          bind k select-pane -U
          bind l select-pane -R
        '';
      };
    };

    environment = {
      gnome.excludePackages = mkIf cfg.desktop [
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
      systemPackages = builtins.concatLists
        [
          (with pkgs; [
            bash
            bat
            direnv
            fzf
            gettext
            git
            gitui
            gnupg
            pinentry
            pinentry-gnome
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
          ])
          (if cfg.hypr then with pkgs; [
            pciutils
            gnome.nautilus
            wlogout
            swaylock
            pamixer
            brightnessctl
            foot
            kitty
            kanshi
            pavucontrol
            dunst
          ] else [ ])
        ];
      etc = {
        "nixos/repl.nix" = {
          text = ''
            {
              pkgs = import <nixpkgs> {};
              lib = import <nixpkgs/lib>;
            }
          '';
        };
      };
    };
    services.xserver = mkIf cfg.desktop {
      enable = true;
      displayManager.gdm.enable = true;
      displayManager.gdm.wayland = true;
      desktopManager.gnome.enable = true;
      layout = "de";
      xkbVariant = "";
    };

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
    security.pam.services.swaylock = mkIf cfg.hypr {
      text = ''
        auth include login
      '';
    };

    services.hardware.bolt.enable = mkIf cfg.hypr true;
    hardware.bluetooth.enable = mkIf cfg.hypr true;
    services.blueman.enable = mkIf cfg.hypr true;

    services.dbus = mkIf cfg.hypr {
      enable = true;
    };
    services.greetd = mkIf cfg.hypr {
      enable = true;
      package = pkgs.tuigreet;
      settings = {
        default_session =
          let
            wayBar = pkgs.writeText "waybar-config" ''
                            "wlr/workspaces": {
                                 "format": "{icon}",
                                 "on-scroll-up": "hyprctl dispatch workspace e+1",
                                 "on-scroll-down": "hyprctl dispatch workspace e-1"
                            }
              			'';
            dunst = pkgs.writeText "dunst-config" (builtins.readFile ./dunst);
            hyprConfig = pkgs.writeText "greetd-hyprland-config" ''
                            exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
                            exec-once = ${pkgs.waybar}/bin/waybar # --config ${wayBar}
                            #exec-once = sleep 3; kanshi --config ${kanshiConfig} 2>&1> ~/klog
                            exec-once = sleep 3; systemctl --user start kanshi.service
                            exec-once = dunst -config ${dunst}

                            #monitor=eDP-1,1920x1200@60,0x0,1
                            #monitor=DP-6,1920x1080@60,0x0,1

                            input {
                              kb_layout = de
                              follow_mouse = 1
                              sensitivity = 0 # -1.0 - 1.0, 0 means no modification.
              				touchpad {
              			      natural_scroll = true
              				}
                            }
                            animations {
                              enabled = true
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
              			  $camod = CTRLALT
              			  $ssmod = SUPERSHIFT
              			  $scmod = CTRLSUPER
              			  $csmod = CTRLSHIFT
                            bind = $mainMod, RETURN, exec, gnome-terminal
                            bind = $mainMod, D, exec, ${pkgs.wofi}/bin/wofi --show drun -I -m -i
              			  bind = $ssmod, Q, killactive,
                            bind = $camod, E, exec, wlogout
              			  bind = $mainMod, V, togglefloating,
              			  bind = $scmod, L, exec, swaylock
              			  bind = $ssmod, F, exec, firefox
              			  bind = $ssmod, T, exec, thunderbird
              			  bind = $ssmod, V, exec, virt-manager
              			  bind = $ssmod, R, exec, rambox
              			  bind = $ssmod, S, exec, signal
              			  bind = $mainMod, E, exec, nautilus

              			  bind=$mainMod,H,movefocus,l
                            bind=$mainMod,L,movefocus,r
                            bind=$mainMod,K,movefocus,u
                            bind=$mainMod,J,movefocus,d
              			  bind=$csmod,h,splitratio,-0.1
                            bind=$csmod,l,splitratio,+0.1
                            #bind=SUPERCONTROL,h,splitratio,-0.1
                            #bind=SUPERCONTROL,l,splitratio,+0.1
                            bind=$camod,F,fullscreen
                            bind=$camod,V, exec, pavucontrol


              			  bind=,XF86AudioRaiseVolume,exec,pamixer -ui 5
                            bind=,XF86AudioLowerVolume,exec,pamixer -ud 5
                            bind=,XF86AudioMute,exec,pamixer -t
              			  bind=$mainMod,F6,exec,brightnessctl set 2%-
                            bind=$mainMod,F7,exec,brightnessctl set +2%

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

                            bind = $mainMod SHIFT, 1, movetoworkspace, 1
                            bind = $mainMod SHIFT, 2, movetoworkspace, 2
                            bind = $mainMod SHIFT, 3, movetoworkspace, 3
                            bind = $mainMod SHIFT, 4, movetoworkspace, 4
                            bind = $mainMod SHIFT, 5, movetoworkspace, 5
                            bind = $mainMod SHIFT, 6, movetoworkspace, 6
                            bind = $mainMod SHIFT, 7, movetoworkspace, 7
                            bind = $mainMod SHIFT, 8, movetoworkspace, 8
                            bind = $mainMod SHIFT, 9, movetoworkspace, 9
                            bind = $mainMod SHIFT, 0, movetoworkspace, 10

                            # common modals
                            windowrule = float,title:^(Open)$
                            windowrule = float,title:^(Choose Files)$
                            windowrule = float,title:^(Save As)$
                            windowrule = float,title:^(Confirm to replace files)$
                            windowrule = float,title:^(File Operation Progress)$

              			  windowrule = center,pavucontrol
                            windowrule = float,pavucontrol
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
    systemd.user.services.kanshi = mkIf cfg.hypr {
      description = "kanshi daemon";
      serviceConfig = {
        Type = "simple";
        ExecStart = ''${pkgs.kanshi}/bin/kanshi -c /home/goeranh/kanshitest'';
      };
    };

    nixpkgs.config.allowUnfree = true;
    networking.firewall.enable = true;

    console.keyMap = "de";

    services.openssh = mkIf cfg.server {
      enable = true;
    };
    services.tailscale.enable = true;
  };
}
