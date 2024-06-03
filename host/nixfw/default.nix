{ config, pkgs, lib, ... }:

{
  sops = {
    # This will automatically import SSH keys as age keys
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = ./secrets.yaml;
    defaultSopsFormat = "yaml";
    secrets = {
      # "dbpass" = {
      #   owner = "librenms";
      #   group = "librenms";
      #   mode = "0440";
      # };
      "intermediatePasswordFile" = {
        owner = "step-ca";
        group = "step-ca";
        mode = "0440";
      };
    };
  };
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  fileSystems."/" =
    {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };


  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    initrd = {
      availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
      kernelModules = [ ];
    };
    kernelModules = [ ];
    extraModulePackages = [ ];
  };

  networking = {
    hostName = "nixfw";
    useDHCP = lib.mkForce false;
    nftables = {
      enable = true;
      ruleset = ''
        table inet filter {
        	chain input {
        		type filter hook input priority 0;
        		iifname lo accept
        		ct state {established, related} accept
        		ip saddr { 10.200.0.0/24, 10.0.0.0/24, 10.0.1.0/24, 10.220.0.2 } ip protocol icmp counter accept
        		ip saddr { 10.200.0.0/24 } ip protocol { tcp, udp, icmp } accept
        		ip6 saddr { fd4:10c9:3065:56db::/64 } counter accept

        		ip daddr { 10.16.23.95 } tcp dport 22 accept
        		iifname "ens19" counter accept

        		iifname { "ens19", "wg0", "wg1" } udp dport { 53 } accept
        		iifname { "ens19" } udp dport { 67 } accept
        		iifname { "ens19", "wg0", "wg1" } tcp dport { 53 } accept
        		iifname { "ens19", "wg0", "wg1" } tcp dport { 8443 } accept

        		counter drop
        	}

        	chain output {
        		type filter hook output priority 0;
        		accept
        	}

        	chain wireguard-to-lan {
        		ip6 saddr { fd4:10c9:3065:56db::/64 } counter accept
        		ip saddr 10.200.0.0/24 ip daddr { 10.0.0.0/24, 10.0.1.0/24 } ip protocol { icmp, tcp, udp } counter accept
        		counter drop
        	}

        	chain lan-outbound {
        		ip saddr { 10.0.0.0/24 } tcp dport { 80, 443 } counter accept
        		ip saddr { 10.0.0.0/24 } ip protocol icmp counter accept
        		iifname "ens19" oifname "ens18" accept
        		counter drop
        	}

        	chain lan-to-lan {
        		# ip saddr { 10.0.0.0/24, 10.0.1.0/24 } ip daddr {10.0.0.0/24, 10.0.1.0/24 } tcp dport { 80, 443 } counter accept
        		# ip saddr { 10.0.0.0/24, 10.0.1.0/24 } ip daddr {10.0.0.0/24, 10.0.1.0/24 } ip protocol icmp counter accept
        		counter accept
        	}

        	chain forward {
        		type filter hook forward priority 0;
        		ct state {established, related} accept
        		iifname "wg0" oifname { "ens18", "ens19", "wg1" } jump wireguard-to-lan
        		iifname "ens19" oifname { "ens18" } jump lan-outbound
        		iifname "wg1" oifname { "ens19" } jump lan-to-lan
        		iifname "ens19" oifname { "wg1" } jump lan-to-lan

        		ip saddr { 10.0.0.0/24 } ip daddr { 10.16.23.1 } accept
        		iifname "ens18" counter drop
        		counter accept
        	}
        }
        table ip nat {
        	chain PREROUTING {
        		type nat hook prerouting priority dstnat; policy accept;
        	}
        }
        table ip6 nat {
        	chain PREROUTING {
        		type nat hook prerouting priority dstnat; policy accept;
        	}
        }
      '';
    };
    firewall = {
      enable = lib.mkForce false;
    };
    nat = {
      enable = true;
      internalInterfaces = [ "ens19" ];
      externalInterface = "ens18";
      forwardPorts = [
      ];
    };
  };
  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "en_US.UTF-8";

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };
  goeranh = {
    server = true;
    trust-builder = false;
    remote-store = false;
  };

  services = {
    bind = {
      enable = true;
      zones = {
        "${config.networking.domain}" =
          let
            zonefile = pkgs.writeText "zone" ''
              $ORIGIN ${config.networking.domain}.
              $TTL 3600
              ${config.networking.domain}.  IN  SOA   nixfw.${config.networking.domain}. goeranh.${config.networking.domain}. ( 2020091025 7200 3600 1209600 3600 )
              ${config.networking.domain}.  IN  NS    nixfw

              onlyoffice.kbuild  IN  CNAME kbuild
              kbuild             IN  A     10.200.0.9
              pitest             IN  A     10.200.0.4
              nixfw              IN  A     10.0.0.1
              zfs-backup         IN  A     10.0.0.5
              pi5                IN  A     10.200.0.8
              dockerhost         IN  A     10.0.0.132
              vaultwarden        IN  A     10.0.0.16
              forgejo            IN  A     10.0.0.21
              hound              IN  CNAME forgejo
              monitoring         IN  A     10.0.0.26
              hydra              IN  A     10.0.0.30
              attic              IN  CNAME hydra
              node5              IN  A     10.200.0.2
              server-gitea       IN  A     100.87.18.24
              workstation        IN  A     10.200.0.3
              workstation        IN  AAAA  fd4:10c9:3065:56db::4
              oraclearm          IN  A     100.87.250.85
            '';
          in
          {
            master = true;
            file = "${zonefile}";
          };
      };
      extraOptions = ''
        	recursion yes;
        	allow-recursion { any; };
      '';
    };
    librenms = {
      enable = false;
      database = {
        passwordFile = "/run/secrets/dbpass";
        createLocally = true;
      };
    };
    step-ca = {
      enable = true;
      settings = import ./step-ca.nix { domain = config.networking.domain; };
      address = "0.0.0.0";
      port = 8443;
      intermediatePasswordFile = "${config.sops.secrets.intermediatePasswordFile.path}";
    };
  };
  environment.systemPackages = with pkgs; [ step-ca ];
  environment.etc."step-ca/password.txt" = {
    source = "${config.sops.secrets.intermediatePasswordFile.path}";
  };

  systemd = {
    network = {
      enable = true;
      netdevs = {
        "50-wg1" = {
          netdevConfig = {
            Kind = "wireguard";
            Name = "wg1";
            MTUBytes = "1300";
          };
          wireguardConfig = {
            PrivateKeyFile = "/var/lib/wireguard/private";
            ListenPort = 51820;
          };
          wireguardPeers = [
            {
              # node5
              wireguardPeerConfig = {
                PublicKey = "hcqq9ayewp2ZuNvqI/BZ+y31G6yuosdmkIFJwO24hUg=";
                AllowedIPs = [ "fd4:10c9:3065:56db::/64" "10.220.0.2" "10.0.1.0/24" ];
              };
            }
          ];
        };
        "10-wg0" = {
          netdevConfig = {
            Kind = "wireguard";
            Name = "wg0";
            MTUBytes = "1300";
          };
          wireguardConfig = {
            PrivateKeyFile = "/var/lib/wireguard/private";
          };
          wireguardPeers = [
            {
              wireguardPeerConfig = {
                PublicKey = "fvGBgD6oOqtcgbbLXDRptL1QomkSlKh29I9EhYQx1iw=";
                AllowedIPs = [ "fd4:10c9:3065:56db::/64" "10.200.0.0/24" ];
                Endpoint = "49.13.134.146:1194";
                PersistentKeepalive = 30;
              };
            }
          ];
        };
      };
      networks = {
        wg0 = {
          matchConfig.Name = "wg0";
          address = [
            "10.200.0.5/24"
            "fd4:10c9:3065:56db::3/64"
          ];
          DHCP = "no";
          networkConfig = {
            #IPMasquerade = true;
            IPv6AcceptRA = false;
            IPForward = true;
          };
        };
        wg1 = {
          matchConfig.Name = "wg1";
          address = [
            "10.220.0.1/24"
          ];
          routes = [
            {
              routeConfig = {
                Gateway = "10.220.0.2";
                Destination = "10.0.1.0/24";
              };
            }
          ];
          networkConfig = {
            IPForward = true;
          };
        };
        ens18 = {
          matchConfig.Name = "ens18";
          address = [
            "10.16.23.95/21"
          ];
          DHCP = "no";
          gateway = [
            "10.16.23.1"
          ];
          networkConfig = {
            IPv6AcceptRA = true;
          };
        };
        ens19 = {
          matchConfig.Name = "ens19";
          address = [
            "10.0.0.1/24"
            "fd6:266a:7309:60ca::1/64"
          ];
          DHCP = "no";
          networkConfig = {
            DHCPServer = true;
            DNS = "10.0.0.1";

            IPv6AcceptRA = false;
            IPv6SendRA = true;
            #DHCPv6PrefixDelegation = "dhcpv6";
            IPv6DuplicateAddressDetection = 1;
          };
          ipv6Prefixes = [
            {
              ipv6PrefixConfig = {
                AddressAutoconfiguration = true;
                # Assign = true;
                Prefix = "fd6:266a:7309:60ca::/64";
              };
            }
          ];
          extraConfig = ''
            [DHCPv6PrefixDelegation]
            	SubnetId=2
            	Assign=yes

            	[IPv6PrefixDelegation]
            	RouterLifetimeSec=900
            	EmitDNS=yes
            	DNS=_link_local
            [DHCPSERVER]
            	ServerAddress = "10.0.0.0/24";
            	PoolOffset = 150;
            	PoolSize = 80;
            	EmitDNS = true;

          '';
        };
      };
    };
    services = {
      "systemd-networkd".environment.SYSTEMD_LOG_LEVEL = "debug";
      snmpd =
        let
          snmpd-config = pkgs.writeText "snmpd.conf" ''
            	rocommunity test123 127.0.0.1/32
            	com2sec notConfigUser  default       public
            	group   notConfigGroup v2c           notConfigUser
            	access  notConfigGroup ""      any       noauth    exact  systemview none  none
            	view    systemview    included   .1.3.6.1.2.1.1
            	view    systemview    included   .1.3.6.1.2.1.25.1.1
            	sysLocation Bladeserver, Keller, Karsdorf
            	sysContact goeran@karsdorf.net
            	sysName ${config.networking.fqdn}
          '';
        in
        {
          enable = true;
          wantedBy = [ "multiuser.target" ];
          description = "SNMP agent";
          after = [ "network.target" ];
          restartIfChanged = true;
          serviceConfig = {
            User = "root";
            Group = "root";
            Restart = "always";
            ExecStart = "${pkgs.net-snmp}/bin/snmpd -Lf /var/log/snmpd.log -c ${snmpd-config.outPath}";
          };
        };
    };
  };

  system.stateVersion = "23.11";
}

