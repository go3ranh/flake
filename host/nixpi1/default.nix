{ config, pkgs, lib, ... }:
let
  hostname = "nixpi1";
  domain = "tailf0ec0.ts.net";
  #adDomain = "goeranh.de";
  #staticIp = "192.168.178.5";
  #adNetbiosName = "goeranhdomain";
  #adWorkgroup = "goeranh";
in
{
  hardware.enableRedistributableFirmware = true;
  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";

  nixpkgs.config.packageOverrides = pkgs: {
    makeModulesClosure = x:
      # prevent kernel install fail due to missing modules
      pkgs.makeModulesClosure (x // { allowMissing = true; });
  };

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;

    kernelParams = lib.mkForce [
      "snd_bcm2835.enable_headphones=1"
      # don't let sd-image-aarch64.nix setup serial console as it breaks bluetooth.
      "console=tty0"
      # allow GPIO access
      "iomem=relaxed"
      "strict-devmem=0"
      # booting sometimes fails with an oops in the ethernet driver. reboot after 5s
      "panic=5"
      "oops=panic"
      # for the patch below
      "compat_uts_machine=armv6l"
    ];

    tmp.useTmpfs = true;
    tmp.tmpfsSize = "80%";
  };
  fileSystems."/" = lib.mkForce {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };

  goeranh = {
    server = true;
  };

  networking = {
    hostName = hostname;
    domain = domain;
    useDHCP = false;
    interfaces.eth0.ipv4.addresses = [{
      address = "192.168.178.5";
      prefixLength = 24;
    }];
    defaultGateway = "192.168.178.1";
    nameservers = [ "1.1.1.1" "8.8.8.8" ];
    firewall = {
      enable = true;
      allowedTCPPorts = [ 80 139 443 445 636 8443 ];
    };
  };

  nix = {
    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";
    settings = {
      builders-use-substitutes = true;
      cores = 4;
      extra-platforms = "armv6l-linux";
      max-jobs = 1;
      system-features = [ ];
      trusted-users = [ "client" ];
    };
  };

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
    vim
    tmux
    wget
  ];

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };
  sdImage.compressImage = false;

  console.keyMap = "de";

  # Rebuild Samba with LDAP, MDNS and Domain Controller support
  #nixpkgs.overlays = [
  #  (self: super: {
  #    samba = (super.samba.override {
  #      enableLDAP = true;
  #      enableMDNS = true;
  #      enableDomainController = true;
  #      enableProfiling = true;
  #    }).overrideAttrs (finalAttrs: previousAttrs: {
  #      pythonPath = with super; [ python3Packages.dnspython tdb ldb talloc ];
  #    });
  #  })
  #];

  services = {
    openssh = {
      enable = true;
    };
    kanidm = {
      enableServer = true;
      unixSettings.pam_allowed_login_groups = [
        "goeranh"
      ];
      serverSettings = {
        tls_key = "/var/lib/${config.networking.fqdn}.key";
        tls_chain = "/var/lib/${config.networking.fqdn}.crt";
        domain = "${config.networking.domain}";
        bindaddress = "0.0.0.0:8443";
        ldapbindaddress = "0.0.0.0:636";
        origin = "https://${config.networking.fqdn}";
      };

      enablePam = true;
      enableClient = true;
      clientSettings.uri = "https://${config.networking.fqdn}:8443";

    };
    #samba = {
    #  enable = true;
    #  enableNmbd = false;
    #  enableWinbindd = false;
    #  configText = ''
    #    # Global parameters
    #    [global
    #        dns forwarder = ${staticIp}
    #        netbios name = ${adNetbiosName}
    #        realm = ${lib.toUpper adDomain}
    #        server role = active directory domain controller
    #        workgroup = ${adWorkgroup}
    #        idmap_ldb:use rfc2307 = yes
    #
    #    [sysvol]
    #        path = /var/lib/samba/sysvol
    #        read only = No
    #
    #    [netlogon]
    #        path = /var/lib/samba/sysvol/${adDomain}/scripts
    #        read only = No
    #  '';
    #};
    # Do not log to flash:
    journald.extraConfig = ''
      Storage=volatile
    '';
  };
  virtualisation.libvirtd.enable = true;

  #environment.etc = {
  #  resolvconf = {
  #    text = ''
  #      search ${adDomain}
  #      nameserver ${staticIp}
  #    '';
  #  };
  #};
  systemd = {
    services = {
      nix-daemon.serviceConfig = {
        LimitNOFILE = lib.mkForce 8192;
        CPUWeight = 5;
        MemoryHigh = "4G";
        MemoryMax = "6G";
        MemorySwapMax = "0";
      };
      #samba-smbd.enable = false;
      #resolvconf.enable = false;
      #samba = {
      #  description = "Samba Service Daemon";
      #  requiredBy = [ "samba.target" ];
      #  partOf = [ "samba.target" ];

      #  serviceConfig = {
      #    ExecStart = "${pkgs.samba}/sbin/samba --foreground --no-process-group";
      #    ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
      #    LimitNOFILE = 16384;
      #    PIDFile = "/run/samba.pid";
      #    Type = "notify";
      #    NotifyAccess = "all"; #may not do anything...
      #  };
      #  unitConfig.RequiresMountsFor = "/var/lib/samba";
      #};
    };
  };

  system.stateVersion = "22.11"; # Did you read the comment?
}

