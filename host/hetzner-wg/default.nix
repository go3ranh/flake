{ self, config, lib, pkgs, ... }: {
  disko.devices = {
    disk = {
      sda = {
        device = "/dev/sda";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02"; # for grub MBR
            };
            root = {
              size = "100%";
              name = "nixos";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
  goeranh = {
    server = true;
    update = true;
    monitoring = false;
  };
  environment.systemPackages = with pkgs; [
    wireguard-tools
  ];

  boot.loader = {
    grub = {
      enable = true;
    };
    systemd-boot.enable = lib.mkForce false;
  };

  users.users.goeranh.initialPassword = "testtest";

  containers = {
    forgejo = {
      config = { config, pkgs, lib, ... }: {
        system.stateVersion = "24.05";
        networking = {
          hostName = "forgejo";
          defaultGateway.address = "192.168.22.1";
          firewall.allowedTCPPorts = [ 22 3000 ];
        };

        services = {
          openssh.enable = true;
          forgejo = {
            enable = true;
            settings = {
              session.COOKIE_SECURE = true;
              server = {
                DOMAIN = "git.goeranh.de";
                ROOT_URL = "https://git.goeranh.de";
              };
              service = {
                DISABLE_REGISTRATION = false;
                REQUIRE_SIGNIN_VIEW = true;
              };
            };
          };
        };
      };
      autoStart = true;
      privateNetwork = true;
      hostBridge = "br0";
      localAddress = "192.168.22.2/24";
    };
    # keycloak = {
    #   config = { config, pkgs, lib, ... }: {
    #     system.stateVersion = "24.05";
    #     networking = {
    #       hostName = "keycloak";
    #       defaultGateway.address = "192.168.22.1";
    #       firewall.allowedTCPPorts = [ 22 8080 ];
    #     };

    #     services = {
    #       openssh.enable = true;
    #     };
    #   };
    #   autoStart = true;
    #   privateNetwork = true;
    #   hostBridge = "br0";
    #   localAddress = "192.168.22.3/24";
    # };
  };

  security.acme = {
    defaults = {
      server = lib.mkForce "https://acme-v02.api.letsencrypt.org/directory";
      #server = lib.mkForce "https://acme-staging-v02.api.letsencrypt.org/directory";
    };
  };
  services = {
    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedTlsSettings = true;
      recommendedProxySettings = true;
      virtualHosts."git.goeranh.de" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://192.168.22.2:3000/";
        };
      };
    };
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
      };
      listenAddresses = [
        {
          addr = "10.200.0.1";
          port = 22;
        }
      ];
    };
    frr = {
      bgpd.enable = true;
      config = ''
        router-id 10.10.0.1
        router bgp 65000
          address-family ipv4 unicast
            network 10.200.0.0/24
          exit-address-family
          neighbor 10.200.0.100 remote-as 65000
      '';
    };
  };
  networking = {
    hostName = "hetzner-wg";
    domain = lib.mkForce "goeranh.de";
    nameservers = [ "9.9.9.9" ];

    useDHCP = false;
    # allow wireguard port
    firewall.enable = lib.mkForce false;
    usePredictableInterfaceNames = false;

    nftables = {
      ruleset = ''
                			  table inet filter {
                					chain input {
                						type filter hook input priority 0; policy drop;
                						iifname lo accept
                						ct state {established, related} accept
                						# allow wireguard traffic
                						ip daddr 49.13.134.146 udp dport { 1194 } counter accept
                						# ip daddr 49.13.134.146 tcp dport { 22 } counter accept
                						ip saddr { 10.200.0.0/24, 10.0.0.0/24 } ip protocol icmp icmp type { destination-unreachable, router-advertisement, time-exceeded, parameter-problem, echo-request } counter accept
                						iifname "wg0" ip6 saddr { fd4:10c9:3065:56db::2 } counter accept
                						ip saddr { 10.200.0.2 } tcp dport { 22, 80, 443 } counter accept
                						ip saddr { 10.200.0.100 } tcp dport { 179 } counter accept

                						ip daddr 49.13.134.146 tcp dport { 22, 80, 443 } counter accept
                					}

                					chain output {
                						type filter hook output priority 0;
                						accept
                					}

                					chain forward-wg {
                						#ip6 saddr {fd4:10c9:3065:56db::/64 } ip6 daddr { fd4:10c9:3065:56db::/64, fd6:266a:7309:60ca::/64 } counter accept
                						#ip saddr { 10.200.0.2, 10.200.0.7 } ip daddr { 10.200.0.0/24, 10.0.0.0/24, 10.0.1.0/24 } ip protocol { tcp, udp, icmp } counter accept
                						## ip saddr 10.200.0.7 ip daddr { 10.0.0.132 } ip protocol tcp counter accept
                						#ip saddr { 10.200.0.0/24 } ip daddr { 10.0.0.1 } tcp dport { 53 } counter accept
                						#ip saddr { 10.200.0.0/24 } ip daddr { 10.0.0.1 } udp dport { 53 } counter accept
                					}
                					chain forward {
                						type filter hook forward priority 0;
                						ct state {established, related} accept
        										iifname "br0" oifname "br0" accept
                						iifname "eth0" ip daddr 192.168.22.2 tcp dport 22 accept
                						#iifname wg0 oifname wg0 counter accept
                						#iifname "wg0" oifname "wg0" jump forward-wg
                						counter accept
                					}
                				}
                			'';
    };
    nat = {
      enable = true;
      internalInterfaces = [ "br0" ];
      externalInterface = "eth0";

      forwardPorts = [
        {
          destination = "192.168.22.2:22";
          proto = "tcp";
          sourcePort = 22;
        }
      ];
    };
  };

  systemd = {
    services = {
      wireguard-setup = {
        enable = true;
        script = ''
          if [ ! -d /var/lib/wireguard ]; then
            mkdir /var/lib/wireguard
          fi
          if [ ! -f /var/lib/wireguard/private ]; then
            ${pkgs.wireguard-tools.outPath}/bin/wg genkey > /var/lib/wireguard/private
          fi
        '';
        wantedBy = [ "multiuser.target" ];
      };
    };
    network = {
      enable = true;
      config = {
        routeTables = {
          wg-blade = 10;
          wg-pi = 20;
          wg-wg = 30;
        };
      };
      netdevs = {
        "10-rloopback" = {
          netdevConfig = {
            Kind = "dummy";
            Name = "rloop";
          };
        };
        "50-wg0" = {
          netdevConfig = {
            Kind = "wireguard";
            Name = "wg0";
            MTUBytes = "1300";
          };
          wireguardConfig = {
            PrivateKeyFile = "/var/lib/wireguard/private";
            ListenPort = 1194;
          };
          wireguardPeers = [
            {
              # node5
              PublicKey = "fyJDrrVSaU6ZBsYY19FPT++PPwX8Muyw9wkA+YxoET0=";
              AllowedIPs = [ "fd8:393:5efa:343::2/64" "10.200.0.2" "fd4:10c9:3065:56db::2" ];
            }
            {
              # node6
              PublicKey = "oVPpcobnyHiXoO6nRT537GgTR2wGljg7bOsTUpoN5Wo=";
              AllowedIPs = [ "10.200.0.12" ];
            }
            # {
            #   # pitest
            #   PublicKey = "F4yaZ9zabNpQSpV+fXAvla6klsv6SppG3Ic3IMlAxnE=";
            #   AllowedIPs = [ "10.200.0.4" ];
            # }
            # {
            #   # nixfw
            #   PublicKey = "gmCG/K+cVYNdz9R7raBcU+OpGF+lQ9ClCGhfbC3THmY=";
            #   AllowedIPs = [ "fd4:10c9:3065:56db::3" "fd6:266a:7309:60ca::/64" "10.200.0.5" "10.0.0.0/24" "10.0.1.0/24" "10.16.17.0/21" ];
            # }
            {
              # iphone 6
              PublicKey = "37dTDJ0/ThwTvJLHDzPSHq7bERSREAgnhCIgKAhc4Qc=";
              AllowedIPs = [ "10.200.0.6" ];
            }
            {
              # iphone 13
              PublicKey = "KvqfWEJYeBSQfPZ5c9J57izdG6HQ8rLWLaeINf0nHk4=";
              AllowedIPs = [ "10.200.0.7" ];
            }
            {
              # pi5
              PublicKey = "h6IOeJC8u5ASiXkLkylrHgGrlYc2xdBnwsVg5SX59FQ=";
              AllowedIPs = [ "fd8:393:5efa:343::8/64" "10.200.0.8" ];
            }
            # {
            #   # kbuild
            #   PublicKey = "o9QBwnoCsK2LV1b0ppjbKlRZMoE8Z73a6uAfsoq/T3o==";
            #   AllowedIPs = [ "10.200.0.9" ];
            # }
            {
              # hosting
              PublicKey = "QLmN/DuZHvTwF3hQOR6ZHBZhVtVS00Hga250nMX/Ez0=";
              AllowedIPs = [ "10.200.0.10" ];
            }
            {
              # uplink wg server
              PublicKey = "CDCHstc28M2dTE0ujkI6KuxhL1aBAhHc+kIIlGECATM=";
              AllowedIPs = [ "fd14:5d1a:7fd7:34e8::/64" "fd8:393:5efa:343::100/64" "10.200.0.100" "10.0.0.0/24" "10.1.1.0/24" "192.168.178.0/24" ];
            }
            {
              # windows desktop
              PublicKey = "QLd9jaLSE0nrJdbWJBaP9dfuSF9hYVXYG5MDEtb4uFc=";
              AllowedIPs = [ "10.200.0.15" ];
            }
            {
              # ipad
              PublicKey = "WjOVzS9O1raWjhDRpIjY1p7NZEUYWN61wNYcvvSlel8=";
              AllowedIPs = [ "10.200.0.16" ];
            }
          ];
        };
        "20-br0" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "br0";
          };
        };
      };
      networks = {
        wg0 = {
          matchConfig.Name = "wg0";
          address = [
            "10.200.0.1/24"
            "fd8:393:5efa:343::1/64"
            #"fd4:10c9:3065:56db::1/64"
          ];
          # routes = [
          #   {
          #     Gateway = "10.200.0.100";
          #     Destination = "10.0.0.0/24";
          #   }
          #   {
          #     Gateway = "10.200.0.100";
          #     Destination = "10.1.1.0/24";
          #   }
          #   {
          #     Gateway = "fd8:393:5efa:343::100";
          #     Destination = "fd14:5d1a:7fd7:34e8::/64";
          #   }
          # ];
          networkConfig = {
            IPMasquerade = "both";
            IPv4Forwarding = true;
            IPv6Forwarding = true;
            #DHCPServer = true;
            DNS = "10.0.0.1";
            #DNS = "9.9.9.9";

            IPv6AcceptRA = false;
            IPv6SendRA = true;
          };
        };
        "eth0" = {
          matchConfig.Name = "eth0";
          address = [
            "2a01:4f8:c013:27a4::1/64"
          ];
          DHCP = "yes";
          gateway = [
            "fe80::1"
          ];
          networkConfig = {
            IPv6AcceptRA = false;
          };
        };
        "40-br0" = {
          matchConfig.Name = "br0";
          bridgeConfig = { };
          networkConfig.LinkLocalAddressing = "no";
          address = [
            "192.168.22.1/24"
          ];
          networkConfig = {
            ConfigureWithoutCarrier = true;
          };
        };
        "40-rloop" = {
          matchConfig.Name = "rloop";
          networkConfig.LinkLocalAddressing = "no";
          address = [
            "10.10.0.1/32"
          ];
          networkConfig = {
            ConfigureWithoutCarrier = true;
          };
        };
      };
    };
  };
}
