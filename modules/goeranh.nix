{ self, inputs, config, arch, nixpkgs, lib, ... }:
with lib;
let
	pkgs = nixpkgs.legacyPackages.${arch};
  buildkeyPub = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF+45vPiX86aXqAosIcy8KAYKOswkGbZyJadJR61YZ9Z";
  deploykeyPub = builtins.readFile ../deploykey.pub;
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
    server = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = "apply server settings";
    };
    remote-store = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = "serve as remote nix store / builder";
    };
    trust-builder = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = "trust nixserver and install keys for store";
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
    update = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = "update the system from flake sources";
    };
  };
  config = {
    sops = mkIf (cfg.trust-builder || cfg.remote-store) {
      # This will automatically import SSH keys as age keys
      age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      defaultSopsFormat = "yaml";
      secrets = {
        "buildkey" = {
          sopsFile = ../buildkeys.yaml;
          owner = "goeranh";
          group = "users";
          mode = "0400";
        };
        "buildkey.pub" = {
          sopsFile = ../buildkeys.yaml;
          owner = "goeranh";
          group = "users";
          mode = "0444";
        };
        "deploykey" = mkIf config.goeranh.remote-store {
          sopsFile = ../deploykey.yaml;
          owner = "goeranh";
          group = "users";
          mode = "0444";
        };
      };
    };
    nix = {
      settings = {
        experimental-features = [ "nix-command" "flakes" ];
        auto-optimise-store = true;
        trusted-public-keys = [
          "kbuild.tailf0ec0.ts.net:NMbE+ZsnodlZU//YNVf6vTXIQyuwOfZ1Ol29aPz56CE="
        ];
        trusted-substituters = mkIf cfg.trust-builder [
          "https://kbuild.tailf0ec0.ts.net"
          "ssh-ng://kbuild"
        ];
      };
      sshServe = mkIf cfg.remote-store {
        enable = true;
        keys = [
          "${buildkeyPub}"
        ];
        protocol = "ssh-ng";
        write = true;
      };
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
    };
    users.users = {
      builder = mkIf cfg.remote-store {
        isNormalUser = true;
        openssh.authorizedKeys.keys = [
          buildkeyPub
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICt3IRfe/ysPl8jKMgYYlo2EEDnoyyQ/bY2u6qqMuWsQ goeranh@node5"
        ];
      };
    };
    nixpkgs.config.permittedInsecurePackages = [
    ];
    users.users.goeranh = {
      isNormalUser = true;
      extraGroups = [ "wheel" "libvirtd" "docker" "networkmanager" "dialout" "plugdev" ];
      openssh.authorizedKeys.keys = mkIf cfg.server [
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBHaU3idFwbk0uY4jooS9dwdBvNLnWfgFRmc7hkSeubSAWnT5J6NM8L8NZrT1ZoiYfebsKmwIn111BGfohZkC6wA= homelab key goeranh"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICt3IRfe/ysPl8jKMgYYlo2EEDnoyyQ/bY2u6qqMuWsQ goeranh@node5"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHZP250IoyRgSYNc/0xilSxJcY36gFnPnm2r7vZlKX6C"
      ];
      packages = builtins.concatLists [
        (with pkgs; [
          dig
          tcpdump
          whois
          rsync
          tailscale
          file
          ntfy-sh
        ])
        (if cfg.desktop then with pkgs; [
          bitwarden
          chromium
          dbeaver
          filezilla
          firefox
          gajim
          gnome3.gnome-terminal
          gpa
          libreoffice
          okular
          poppler_utils
          quickemu
          shotwell
          signal-desktop
          thunderbird
          tor-browser-bundle-bin
          vieb
          virt-manager
          virt-viewer
          vlc

          # discord
          # obsidian
          # rambox
          # spotify
        ] else [ ])
        (if cfg.development then with pkgs; [
          binwalk
          file
          ghidra
          gnome-builder
          libxcrypt
          meson
          gnumake
          cmake
          ninja
          nodejs

          # gitkraken
          # jetbrains.clion
          # jetbrains.idea-community
          # jetbrains.datagrip
          # jetbrains.jdk
          # jetbrains.phpstorm
          # jetbrains.webstorm
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
        interactiveShellInit = ''
          					source ${self.packages.${arch}.settings.bashrc.outPath}
          					source ${self.packages.${arch}.settings.goeranh.outPath}
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
          set -g pane-border-status top
          set -g pane-border-format " [ ###P #T ] "
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
          bind -n M-O display-popup
          bind -n M-t display-popup
          bind u display-popup
          bind h select-pane -L
          bind j select-pane -D
          bind k select-pane -U
          bind l select-pane -R
          
          bind -n M-H previous-window
          bind -n M-L next-window
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
          self.packages.${arch}.customvim
          (with pkgs; [
            linuxKernel.packages.linux_zen.perf
            bpftrace
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
            nix-direnv
            nmap
            ripgrep
            tmux
            unzip
            wget
            zellij
          ])
          (if cfg.desktop then with pkgs; [
            signal-desktop
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

    nixpkgs.config.allowUnfree = true;
    networking.firewall.enable = true;
    networking.nftables.enable = true;
    networking.domain = "tailf0ec0.ts.net";

    console.keyMap = "de";

    services.openssh = mkIf cfg.server {
      enable = true;
      openFirewall = true;
    };
    services.tailscale.enable = true;

    systemd.services = {
      autoupdate = mkIf cfg.update {
        enable = true;
        path = with pkgs; [
          nixos-rebuild
          git
        ];
        script = ''
          					if [ ! -d /tmp/flakeathome ]; then
          						cd /tmp
          						${pkgs.git}/bin/git clone https://pitest.tailf0ec0.ts.net/git/goeranh/flakeathome.git
          					fi
          					cd /tmp/flakeathome
          					${pkgs.git}/bin/git pull
          				  nixos-rebuild switch --flake .#
          				'';
        startAt = "daily";
      };
    };
  };
}
