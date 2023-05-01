{ config, pkgs, lib, ... }: {
  config = {
    users.users.goeranh = {
      isNormalUser = true;
      extraGroups = [ "wheel" "libvirtd" "docker" "networkmanager" "dialout" ];
      packages = with pkgs; [
        bitwarden
        btrfs-progs
        chromium
        dbeaver
        discord
        filezilla
        firefox
        gajim
        ghidra
        gitkraken
        gnome3.gnome-terminal
        gnome-builder
        jetbrains.idea-community
        jetbrains.jdk
        libreoffice
        okular
        poppler_utils
        quickemu
        rambox
        shotwell
        signal-desktop
        spotify
        tailscale
        thunderbird
        vieb
        virt-manager
        virt-viewer
        vlc
      ];
    };

    environment.systemPackages = with pkgs; [
      bash
      bat
      direnv
      exa
      fzf
      gcc
      gef
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

    services.tailscale.enable = true;
  };
}
