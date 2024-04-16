{ self, inputs, config, arch, nixpkgs, lib, ... }:
with lib;
let
  gnomeexclude = with nixpkgs.legacyPackages.${arch}; [
    gnome.baobab # disk usage analyzer
    gnome.cheese # photo booth
    #eog         # image viewer
    #epiphany    # web browser
    gnome.simple-scan # document scanner
    #totem       # video player
    gnome.yelp # help viewer
    gnome.evince # document viewer
    gnome.geary # email client

    # these should be self explanatory
    gnome.gnome-calculator
    gnome.gnome-calendar
    gnome.gnome-clocks
    gnome.gnome-contacts
    gnome.gnome-font-viewer
    gnome.gnome-logs
    gnome.gnome-maps
    gnome.gnome-music
    gnome.gnome-weather
    gnome-connections
  ];
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
    security = {
      pki = {
        certificateFiles = [
          ../ca-chain.cert.pem
        ];
      };
    };
    nix = {
      registry = {
        fah.flake = self;
        nixpkgs.flake = inputs.nixpkgs;
      };
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
        (with nixpkgs.legacyPackages.${arch}; [
          dig
          jq
          tcpdump
          whois
          rsync
          # tailscale
          file
        ])
        (if cfg.desktop then with nixpkgs.legacyPackages.${arch}; [
          bitwarden
          pika-backup
          newsflash
          wike
          chromium
          dbeaver
          #filezilla
          ferdium
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
          super-productivity
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
        (if cfg.development then with nixpkgs.legacyPackages.${arch}; [
          binwalk
          file
          ghidra
          #gnome-builder
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
        (if cfg.gaming then with nixpkgs.legacyPackages.${arch}; [
          lutris
          wine
          wine-wayland
        ] else [ ])
      ];
    };

    programs = {
      # steam = mkIf cfg.gaming {
      #   enable = true;
      #   remotePlay.openFirewall = true;
      # };
      dconf.profiles.user.databases = lib.mkIf cfg.desktop [
        {
          settings = with lib.gvariant; {
            "org/gnome/desktop/calendar" = {
              show-weekdate = true;
            };

            "org/gnome/desktop/input-sources" = {
              sources = [ [ "xkb" "de" ] ];
              xkb-options = [ "terminate:ctrl_alt_bksp" ];
            };

            "org/gnome/desktop/interface" = {
              color-scheme = "prefer-dark";
              enable-hot-corners = false;
              font-antialiasing = "grayscale";
              font-hinting = "slight";
              show-battery-percentage = true;
            };

            "org/gnome/desktop/peripherals/touchpad" = {
              tap-to-click = true;
              two-finger-scrolling-enabled = true;
            };

            "org/gnome/desktop/session" = {
              idle-delay = mkInt32 0;
            };

            "org/gnome/desktop/wm/keybindings" = {
              begin-move = [ "<Alt>m" ];
              begin-resize = [ "<Alt>r" ];
              close = [ "<Shift><Super>q" ];
              maximize = [ "<Super>k" ];
              #minimize=@as []
              move-to-center = [ "<alt>c+m" ];
              move-to-monitor-down = [ "<Shift><Super>j" ];
              move-to-monitor-left = [ "<Shift><Super>h" ];
              move-to-monitor-right = [ "<Shift><Super>l" ];
              move-to-monitor-up = [ "<Shift><Super>k" ];
              move-to-workspace-1 = [ "<Primary><Shift><Alt>exclam" ];
              move-to-workspace-2 = [ "<Primary><Shift><Alt>quotedbl" ];
              move-to-workspace-3 = [ "<Primary><Shift><Alt>section" ];
              move-to-workspace-4 = [ "<Primary><Shift><Alt>dollar" ];
              move-to-workspace-5 = [ "<Primary><Shift><Alt>percent" ];
              move-to-workspace-left = [ "<Primary><Shift><Alt>h" ];
              move-to-workspace-right = [ "<Primary><Shift><Alt>l" ];
              #switch-applications=@as []
              #switch-applications-backward=@as []
              switch-to-workspace-1 = [ "<Primary><Alt>1" ];
              switch-to-workspace-2 = [ "<Primary><Alt>2" ];
              switch-to-workspace-3 = [ "<Primary><Alt>3" ];
              switch-to-workspace-4 = [ "<Primary><Alt>4" ];
              switch-to-workspace-5 = [ "<Primary><Alt>5" ];
              switch-to-workspace-6 = [ "<Primary><Alt>6" ];
              switch-to-workspace-7 = [ "<Primary><Alt>7" ];
              switch-to-workspace-8 = [ "<Primary><Alt>8" ];
              switch-to-workspace-9 = [ "<Primary><Alt>9" ];
              switch-to-workspace-10 = [ "<Primary><Alt>0" ];
              switch-to-workspace-11 = [ "<Primary><Alt>q" ];
              switch-to-workspace-12 = [ "<Primary><Alt>w" ];
              switch-to-workspace-left = [ "<Primary><Alt>h" ];
              switch-to-workspace-right = [ "<Primary><Alt>l" ];
              switch-windows = [ "<Alt>Tab" ];
              switch-windows-backward = [ "<Shift><Alt>Tab" ];
              toggle-fullscreen = [ "<Control><Super>f" ];
              unmaximize = [ "<Super>j" ];
            };

            "org/gnome/desktop/wm/preferences" = {
              audible-bell = false;
              button-layout = "appmenu:close";
              num-workspaces = mkInt32 20;
            };

            "org/gnome/epiphany" = {
              ask-for-default = false;
            };

            "org/gnome/file-roller/dialogs/extract" = {
              recreate-folders = true;
              skip-newer = false;
            };

            "org/gnome/file-roller/listing" = {
              list-mode = "as-folder";
              name-column-width = mkInt32 250;
              show-path = false;
              sort-method = "name";
              sort-type = "ascending";
            };

            "org/gnome/file-roller/ui" = {
              sidebar-width = mkInt32 200;
            };

            "org/gnome/mutter" = {
              attach-modal-dialogs = true;
              dynamic-workspaces = true;
              edge-tiling = true;
              #experimental-features=@as []
              focus-change-on-pointer-rest = true;
              workspaces-only-on-primary = false;
            };

            "org/gnome/mutter/keybindings" = {
              toggle-tiled-left = [ "<Super>h" ];
              toggle-tiled-right = [ "<Super>l" ];
            };

            "org/gnome/nautilus/compression" = {
              default-compression-format = "zip";
            };

            # [org/gnome/nautilus/list-view]
            # default-column-order=['name', 'size', 'type', 'owner', 'group', 'permissions', 'where', 'date_modified', 'date_modified_with_time', 'date_accessed', 'date_created', 'recency', 'detailed_type']
            # default-visible-columns=['name', 'size', 'type', 'owner', 'group', 'permissions', 'date_modified']
            # default-zoom-level='small'

            # [org/gnome/nautilus/preferences]
            # default-folder-viewer='list-view'
            # migrated-gtk-settings=true
            # search-filter-time-type='last_modified'
            # search-view='list-view'

            # [org/gnome/settings-daemon/plugins/color]
            # night-light-enabled=false
            # night-light-schedule-automatic=false
            # night-light-schedule-from=6.0
            # night-light-temperature=uint32 2427
            "org/gnome/settings-daemon/plugins/media-keys" = {
              control-center = [ "<Super>i" ];
              custom-keybindings = [
                "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
                "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
                "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/"
                "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/"
                "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6/"
                "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom7/"
                "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
                "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5/"
                "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom8/"
                "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom9/"
                "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom10/"
                "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom11/"
              ];
              email = [ "<Shift><Super>t" ];
              home = [ "<Super>e" ];
              screensaver = [ "<Primary><Super>l" ];
              #terminal=@as []
            };

            "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
              binding = "<Shift><Super>f";
              command = "nice -n 40 firefox";
              name = "firefox";
            };

            "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
              binding = "<Control><Alt>t";
              command = "tor-browser";
              name = "tor";
            };

            "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
              binding = "<Shift><Super>v";
              command = "virt-manager";
              name = "virt-manager";
            };

            "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3" = {
              binding = "<Shift><Super>r";
              command = "ferdium";
              name = "rambox";
            };

            "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4" = {
              binding = "<Shift><Super>s";
              command = "signal-desktop";
              name = "signal";
            };

            "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5" = {
              binding = "<Shift><Super>o";
              command = "obsidian";
              name = "obsidian";
            };

            "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6" = {
              binding = "<Shift><Super>n";
              command = "vieb";
              name = "vieb";
            };

            "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom7" = {
              binding = "<Super>Return";
              command = "gnome-terminal";
              name = "terminal";
            };

            "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom8" = {
              binding = "<Shift><Super>i";
              command = "idea-community";
              name = "idea-community";
            };

            "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom9" = {
              binding = "<Shift><Super>p";
              command = "phpstorm";
              name = "phpstorm";
            };

            "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom10" = {
              binding = "<Shift><Super>y";
              command = "nice -n 40 firefox -p youtube";
              name = "firefox";
            };

            "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom11" = {
              binding = "<Control><Alt>s";
              command = "super-productivity";
              name = "super-productivity";
            };

            "org/gnome/settings-daemon/plugins/power" = {
              sleep-inactive-ac-timeout = mkInt32 7200;
            };

            "org/gnome/shell" = {
              disable-user-extensions = true;
              favorite-apps = [ "org.gnome.Nautilus.desktop" "firefox.desktop" "org.gnome.Terminal.desktop" ];
              last-selected-power-profile = "performance";
              remember-mount-password = false;
            };

            "org/gnome/shell/keybindings" = {
              show-screenshot-ui = [ "<Primary><Alt>p" ];
            };

            "org/gnome/system/location" = {
              enabled = false;
            };

            "rg/gnome/terminal/legacy" = {
              always-check-default-terminal = false;
              default-show-menubar = false;
              menu-accelerator-enabled = false;
              theme-variant = "system";
            };

            "rg/gnome/terminal/legacy/profiles:" = {
              default = "383ef43c-768d-4f0b-aa2b-62d8cb5bf800";
              list = [ "b1dcc9dd-5262-4d8d-a863-c897e6d979b9" "383ef43c-768d-4f0b-aa2b-62d8cb5bf800" ];
            };

            "rg/gnome/terminal/legacy/profiles:/:383ef43c-768d-4f0b-aa2b-62d8cb5bf800" = {
              audible-bell = false;
              background-color = "rgb(255,255,255)";
              default-size-columns = mkInt32 120;
              default-size-rows = mkInt32 36;
              font = "Monospace 14";
              foreground-color = "rgb(23,20,33)";
              use-system-font = false;
              use-theme-colors = true;
              visible-name = "light";
            };

            "org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9" = {
              audible-bell = false;
              background-color = "rgb(23,20,33)";
              default-size-columns = mkInt32 120;
              default-size-rows = mkInt32 36;
              font = "Monospace 14";
              foreground-color = "rgb(208,207,204)";
              use-system-font = false;
              use-theme-colors = false;
            };

            "org/virt-manager/virt-manager/confirm" = {
              delete-storage = false;
              forcepoweroff = false;
              removedev = false;
              unapplied-dev = false;
            };

            "org/virt-manager/virt-manager/vmlist-fields" = {
              disk-usage = true;
              network-traffic = true;
            };

            "system/proxy" = {
              mode = "none";
            };
          };
        }
      ];
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
        plugins = with nixpkgs.legacyPackages.${arch}.tmuxPlugins; [
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

    xdg.portal = lib.mkIf cfg.desktop {
      enable = true;
      xdgOpenUsePortal = true;
      config = {
        gnome = {
          default = [
            "gnome"
            "gtk"
          ];
          "org.freedesktop.impl.portal.Secret" = [
            "gnome-keyring"
          ];
        };
      };
    };

    environment = {
      gnome.excludePackages = mkIf cfg.desktop gnomeexclude;
      systemPackages = builtins.concatLists
        [
          [ self.packages.${arch}.customvim ]
          (with nixpkgs.legacyPackages.${arch}; [
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
          (if cfg.desktop then with nixpkgs.legacyPackages.${arch}; [
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
    services.gnome = mkIf cfg.desktop {
      tracker.enable = true;
      tracker-miners.enable = true;
    };
    services.xserver = mkIf cfg.desktop {
      enable = true;
      displayManager.gdm.enable = true;
      displayManager.gdm.wayland = true;
      desktopManager.gnome.enable = true;
      xkb = {
        layout = "de";
        variant = "";
      };
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
    networking.nameservers = [ "100.87.17.62" "9.9.9.9" ];
    networking.domain = "netbird.selfhosted";
    networking.search = [ "netbird.selfhosted" ];

    console.keyMap = "de";

    services.openssh = mkIf cfg.server {
      enable = true;
      openFirewall = true;
    };
    services.netbird = {
      enable = true;
    };
    # services.tailscale = {
    #   enable = false;
    #   permitCertUid = mkIf config.services.nginx.enable "${builtins.toString config.users.users.nginx.uid}";
    # };

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
      # tscert = mkIf config.services.nginx.enable {
      #   enable = true;
      #   path = with pkgs; [
      #     tailscale
      #   ];
      #   script = ''
      #               tailscale cert ${config.networking.fqdn}
      #     				'';
      #   startAt = "daily";
      #   unitConfig = {
      #     User = config.users.users.nginx.name;
      #     WorkingDirectory = "/var/lib";
      #   };
      # };
    };
  };
}
