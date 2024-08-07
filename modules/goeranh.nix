{ self, inputs, config, arch, nixpkgs, lib, ... }:
with lib;
let
  domain = "goeranh.selfhosted";
  gnomeexclude = with nixpkgs.legacyPackages.${arch}; [
    baobab # disk usage analyzer
    gnome.cheese # photo booth
    #eog         # image viewer
    #epiphany    # web browser
    simple-scan # document scanner
    #totem       # video player
    yelp # help viewer
    evince # document viewer
    gnome.geary # email client

    # these should be self explanatory
    gnome.gnome-calendar
    #gnome-clocks
    #gnome-contacts
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
    monitoring = mkOption {
      type = types.bool;
      default = true;
      example = true;
      description = "enable prometheus and loki monitoring and log aggregation";
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
      acme = {
        defaults = {
          server = "https://nixfw.${config.networking.domain}:8443/acme/acme/directory";
          renewInterval = "daily";
          email = "goeran@karsdorf.net";
          enableDebugLogs = true;
          validMinDays = 1;
          extraLegoRunFlags = [
          ];
        };
        acceptTerms = true;
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
          "hydra.goeranh.selfhosted:izMfkAqpPQB0mp/ApBzCyj8rGANmjz12T0c91GJSYZI="
        ];
        trusted-substituters = mkIf cfg.trust-builder [
          "https://hydra.nixos.org/"
          # "https://hydra.${config.networking.domain}"
          # "https://attic.${config.networking.domain}"
        ];
        allowed-users = [
          "goeranh"
          "root"
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
		  "electron"
    ];
    users.users.goeranh = {
      isNormalUser = true;
      extraGroups = [ "wheel" "libvirtd" "docker" "networkmanager" "dialout" "plugdev" ];
      openssh.authorizedKeys.keys = mkIf cfg.server [
        #"ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBHaU3idFwbk0uY4jooS9dwdBvNLnWfgFRmc7hkSeubSAWnT5J6NM8L8NZrT1ZoiYfebsKmwIn111BGfohZkC6wA= homelab key goeranh"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICt3IRfe/ysPl8jKMgYYlo2EEDnoyyQ/bY2u6qqMuWsQ goeranh@node5"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHZP250IoyRgSYNc/0xilSxJcY36gFnPnm2r7vZlKX6C"
				"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEkaHbbPLiWNg7pbidfv06d9GsOk4QUVivfIazriZ3EG" # handy
      ];
      packages = builtins.concatLists [
        (with nixpkgs.legacyPackages.${arch}; [
          dig
          file
          jq
          rsync
          tcpdump
          whois
          # tailscale
        ])
        (if cfg.desktop then with nixpkgs.legacyPackages.${arch}; [
          bitwarden
          chromium
          calibre
          dbeaver-bin
          ferdium
          filezilla
          firefox
          gajim
          gnome.gnome-terminal
          gpa
          libreoffice
          #logseq
          newsflash
          okular
          pika-backup
          poppler_utils
          qpwgraph
          quickemu
          shotwell
          signal-desktop
          #super-productivity
          thunderbird
          tor-browser-bundle-bin
          vieb
          virt-manager
          virt-viewer
          vlc
          wike

          # discord
          # obsidian
          # spotify
          # rambox
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
          #jetbrains.idea-community
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

            "org/gnome/nautilus/list-view" = {
              use-tree-view = "true";
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
              command = "logseq";
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
          vim-tmux-navigator
        ];
        extraConfig = ''
                              bind '§' splitw -hc '#{pane_current_path}'
                              bind -n M-z resize-pane -Z
                              #open copy mode y
                              bind y copy-mode
                              #vi scrolling
                              set-window-option -g mode-keys vi
                              # set -g pane-border-status top
                              # set -g pane-border-format " [ ###P #T ] "
                              #u/f pageup/pagedown
                              bind -T copy-mode u send -X page-up
                              bind -T copy-mode f send -X page-down
                    					is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
                        | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?|fzf)(diff)?$'"

                      bind-key -n 'M-h' if-shell "$is_vim" 'send-keys M-h'  'select-pane -L'
                      bind-key -n 'M-j' if-shell "$is_vim" 'send-keys M-j'  'select-pane -D'
                      bind-key -n 'M-k' if-shell "$is_vim" 'send-keys M-k'  'select-pane -U'
                      bind-key -n 'M-l' if-shell "$is_vim" 'send-keys M-l'  'select-pane -R'

                      # Forwarding <C-\\> needs different syntax, depending on tmux version
                      tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'
                      if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
                        "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\'  'select-pane -l'"
                      if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
                        "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\\\'  'select-pane -l'"

                      bind-key -T copy-mode-vi 'M-h' select-pane -L
                      bind-key -T copy-mode-vi 'M-j' select-pane -D
                      bind-key -T copy-mode-vi 'M-k' select-pane -U
                      bind-key -T copy-mode-vi 'M-l' select-pane -R
                      bind-key -T copy-mode-vi 'M-\' select-pane -l
          
                    # use bind keys
                              # bind -n M-h select-pane -L
                              # bind -n M-l select-pane -R
                              # bind -n M-k select-pane -U
                              # bind -n M-j select-pane -D
                              # bind -n M-H select-pane -L
                              # bind -n M-L select-pane -R
                              # bind -n M-K select-pane -U
                              # bind -n M-J select-pane -D
                              # bind -n M-O display-popup
                              # bind -n M-t display-popup
                              # bind u display-popup
                              # bind h select-pane -L
                              # bind j select-pane -D
                              # bind k select-pane -U
                              # bind l select-pane -R
                              # 
                              bind -n M-H previous-window
                              bind -n M-L next-window
                              bind -n M-Enter new-window
                              bind -n M-a split-pane -v
                              bind -n M-s split-pane -h
          										# clear screen
                              bind -n C-l send-keys C-l
        '';
      };
      gnupg.agent = {
        enable = true;
        pinentryPackage = lib.mkIf cfg.desktop pkgs.pinentry-gnome3;
        enableSSHSupport = true;
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
            attic-client
            bash
            bat
            bpftrace
            direnv
            fzf
            gettext
            gitFull
            gitui
            gnupg
            gofu
            htop
            linuxKernel.packages.linux_zen.perf
            nix-direnv
            nmap
            pinentry
            ripgrep
            tmux
            unzip
            wget
            wireguard-tools
            zellij
            zoxide
          ])
          (if cfg.desktop then with nixpkgs.legacyPackages.${arch}; [
            signal-desktop
          ] else [ ])
        ];
      etc = {
        # "resolv.conf" = lib.mkDefault {
        #   text = ''
        #     domain ${domain}
        #     nameserver 10.0.0.1
        #     #nameserver 9.9.9.9
        #   '';
        # };
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

    networking.firewall.enable = true;
    networking.nftables.enable = true;
    networking.nameservers = [ "10.0.0.1" ];
    networking.domain = "${domain}";
    networking.search = [ "${domain}" ];

    console.keyMap = "de";

    services.resolved = {
      enable = true;
      domains = [ "${config.networking.domain}" ];
      fallbackDns = [ "10.0.0.1" "9.9.9.9" ];
    };
    services.openssh = mkIf cfg.server {
      enable = true;
      openFirewall = true;
    };

    services = {
      nginx.statusPage = true;
      #prometheus.exporters = {
      #  # Export NginX if the NginX service is enabled
      #  nginx = {
      #    enable = config.services.nginx.enable;
      #    listenAddress = "127.0.0.1";
      #    telemetryPath = "/nginx";
      #  };
      #  node = {
      #    enable = true;
      #    enabledCollectors = [
      #      "cpu"
      #      "ethtool"
      #      "netdev"
      #      "systemd"
      #    ];
      #    port = 9002;
      #  };
      #};


      ####### ###### begin
      ####### ###### begin
      ####### ###### begin
      #grafana-agent =
      #  let
      #    backend_ip = "10.0.0.26";
      #  in
      #  {
      #    enable = true;
      #    extraFlags = [ "-disable-reporting" ];
      #    settings = {
      #      # Use integrated exporters for supported services
      #      # Other services use 'services.prometheus.exporters' above
      #      integrations = {
      #        agent.enabled = true;
      #        apache_http = {
      #          enabled = config.services.httpd.enable;
      #          scrape_integration = config.services.httpd.enable;
      #        };
      #        # Postgres könnte noch Probleme wegen falscher Konfiguration machen, deshalb erstmal nicht aktiv
      #        postgres_exporter = {
      #          enabled = config.services.postgresql.enable;
      #          scrape_integration = config.services.postgresql.enable;
      #        };
      #      };
      #      # Configure scraping of metrics to send to prometheus
      #      metrics = {
      #        global = {
      #          remote_write = [{
      #            name = "monitoring-backend";
      #            url = "http://${backend_ip}:9002/api/v1/write";
      #            # Set the instance label to the FQDN of the instance it originates from
      #            write_relabel_configs = [
      #              {
      #                target_label = "instance";
      #                replacement = "${config.networking.fqdn}";
      #              }
      #            ];
      #          }];
      #        };
      #        configs = [{
      #          name = "default";
      #          # Generate a scrape config for all enabled prometheus exporters
      #          # Applications natively providing metrics endpoints have to be manually configured
      #          scrape_configs = (
      #            let
      #              exports = config.services.prometheus.exporters;
      #              active_exports = builtins.filter (exporter: builtins.isAttrs exports.${exporter} && exports.${exporter}.enable) (builtins.attrNames exports);
      #            in
      #            builtins.foldl'
      #              (
      #                result: export_name: with config.services.prometheus.exporters.${export_name};
      #                result ++ [{
      #                  job_name = export_name;
      #                  #metrics_path = "${telemetryPath}";
      #                  static_configs = [{
      #                    targets = [ "${listenAddress}:${toString port}" ];
      #                    labels = {
      #                      # TODO Don't know what's needed here
      #                      exporter = export_name;
      #                    };
      #                  }];
      #                }]
      #              )
      #              [ ]
      #              active_exports
      #          ) ++ [ ];
      #        }];
      #      };
      #      # Configure scraping of logs to write to loki
      #      # Docs: https://grafana.com/docs/loki/latest/send-data/promtail/configuration/#scrape_configs
      #      logs = {
      #        positions_directory = "\${STATE_DIRECTORY}/positions/";
      #        global = {
      #          clients = [{
      #            url = "http://${backend_ip}:3030/loki/api/v1/push";
      #          }];
      #        };
      #        configs = [{
      #          name = "default";
      #          scrape_configs = [
      #            {
      #              job_name = "journal";
      #              journal = {
      #                labels = {
      #                  job = "systemd-journal";
      #                };
      #                max_age = "12h";
      #              };
      #              relabel_configs = [
      #                {
      #                  source_labels = [
      #                    "__journal__systemd_unit"
      #                  ];
      #                  target_label = "systemd_unit";
      #                }
      #                {
      #                  source_labels = [
      #                    "__journal__hostname"
      #                  ];
      #                  target_label = "nodename";
      #                }
      #                {
      #                  source_labels = [
      #                    "__journal_syslog_identifier"
      #                  ];
      #                  target_label = "syslog_identifier";
      #                }
      #              ];
      #            }
      #          ] ++ [ ];
      #        }];
      #      };
      #    };
      #  };

      ####### ###### end
      ####### ###### end
      ####### ###### end


    };


    services.promtail = mkIf cfg.monitoring {
      enable = true;
      configuration = {
        server = {
          http_listen_port = 3031;
          grpc_listen_port = 0;
        };
        positions = {
          filename = "/tmp/positions.yaml";
        };
        clients = [{
          url = "http://monitoring.${domain}:3030/loki/api/v1/push";
        }];
        scrape_configs = [
          {
            job_name = "journal";
            journal = {
              max_age = "12h";
              labels = {
                job = "systemd-journal";
                host = "${config.networking.hostName}";
              };
            };
            relabel_configs = [{
              source_labels = [ "__journal__systemd_unit" ];
              target_label = "unit";
            }];
          }
        ];
      };
    };

    systemd.services = { };
  };
}
