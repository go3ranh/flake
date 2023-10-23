# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      <home-manager/nixos>
    ];
  home-manager.users.goeranh.dconf.settings = {
    "org/gnome/boxes" = {
      first-run = false;
      view = "icon-view";
      window-maximized = true;
      window-position = [ 26 23 ];
      window-size = [ 768 600 ];
    };

    "org/gnome/desktop/wm/keybindings" = {
      begin-move = [ "<Alt>m" ];
      begin-resize = [ "<Alt>r" ];
      close = [ "<Shift><Super>q" ];
      maximize = [ "<Super>k" ];
      minimize = [ ];
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
      switch-to-workspace-1 = [ "<Primary><Alt>1" ];
      switch-to-workspace-10 = [ "<Primary><Alt>0" ];
      switch-to-workspace-2 = [ "<Primary><Alt>2" ];
      switch-to-workspace-3 = [ "<Primary><Alt>3" ];
      switch-to-workspace-4 = [ "<Primary><Alt>4" ];
      switch-to-workspace-5 = [ "<Primary><Alt>5" ];
      switch-to-workspace-6 = [ "<Primary><Alt>6" ];
      switch-to-workspace-7 = [ "<Primary><Alt>7" ];
      switch-to-workspace-8 = [ "<Primary><Alt>8" ];
      switch-to-workspace-9 = [ "<Primary><Alt>9" ];
      switch-to-workspace-left = [ "<Primary><Alt>h" ];
      switch-to-workspace-right = [ "<Primary><Alt>l" ];
      switch-windows-backward = [ "<Shift><Alt>Tab" ];

      unmaximize = [ "<Super>j" ];
    };

    "org/gnome/desktop/wm/preferences" = {
      audible-bell = false;
      num-workspaces = 10;
    };

    "org/gnome/mutter" = {
      dynamic-workspaces = true;
      experimental-features = [ ];
      workspaces-only-on-primary = false;
    };

    "org/gnome/mutter/keybindings" = {
      toggle-tiled-left = [ "<Super>h" ];
      toggle-tiled-right = [ "<Super>l" ];
    };

    "org/gnome/nautilus/compression" = {
      default-compression-format = "zip";
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      control-center = [ "<Super>i" ];
      custom-keybindings = [ "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/" "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/" "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/" "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/" "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/" "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5/" "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6/" "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom7/" ];
      email = [ "<Shift><Super>t" ];
      home = [ "<Super>e" ];
      screensaver = [ "<Primary><Super>l" ];
      terminal = [ ];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Shift><Super>f";
      command = "firefox";
      name = "firefox";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
      binding = "<Shift><Super>v";
      command = "virt-manager";
      name = "virt-manager";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3" = {
      binding = "<Shift><Super>r";
      command = "rambox";
      name = "rambox";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4" = {
      binding = "<Shift><Super>s";
      command = "signal-desktop";
      name = "signal";
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

    "org/gnome/shell/keybindings" = {
      screenshot = [ "<Shift><Super>p" ];
      show-screenshot-ui = [ "<Primary><Alt>p" ];
    };

    "org/gnome/system/location" = {
      enabled = false;
    };

  };
}
