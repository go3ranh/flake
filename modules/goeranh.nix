{config, pkgs, lib, ...}:{
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

  services.tailscale.enable = true;
}
