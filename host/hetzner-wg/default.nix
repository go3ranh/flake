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
    systemd-boot.enable = lib.mkForce false;
    grub.enable = true;
  };

  users.users.goeranh.initialPassword = "testtest";

  services = {
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
      };
    };
  };
  networking = {
    hostName = "hetzner-wg";

    useDHCP = false;
    # allow wireguard port
    firewall.allowedUDPPorts = [ 1194 ];
    firewall.enable = lib.mkForce false;
    usePredictableInterfaceNames = false;

		nftables = {
			# tables = {
			# 	filter = {
			# 		family = "inet";
			# 		enable = true;
			# 		content = ''
      #       chain input {
      #         type filter hook input priority 0;
      #         iifname lo accept
      #         ct state {established, related} accept

      #         # allow wireguard traffic
      #         ip daddr 49.13.134.146 udp dport { 51820 } counter name wireguard-udp accept

      #         ip saddr { 10.200.0.2, 10.200.0.5 } ip protocol icmp icmp type { destination-unreachable, router-advertisement, time-exceeded, parameter-problem, echo-request } counter name node5-ping accept
      #         ip saddr { 10.200.0.2 } tcp dport { 22, 80, 443 } counter name node5-traffic accept
      #       }
			# 		'';
			# 	};
			# };
			ruleset = ''
			  table inet filter {
					chain input {
						type filter hook input priority 0;
						iifname lo accept
						ct state {established, related} accept
						# allow wireguard traffic
						ip daddr 49.13.134.146 udp dport { 1194 } counter accept
						# ip daddr 49.13.134.146 tcp dport { 22 } counter accept
						ip saddr { 10.200.0.2, 10.200.0.5 } ip protocol icmp icmp type { destination-unreachable, router-advertisement, time-exceeded, parameter-problem, echo-request } counter accept
						ip saddr { 10.200.0.2 } tcp dport { 22, 80, 443 } counter accept

						counter drop
					}

					chain output {
						type filter hook output priority 0;
						accept
					}

					chain forward-wg {
						ip saddr 10.200.0.2 ip daddr { 10.200.0.0/24, 10.0.0.0/24, 10.0.1.0/24 } ip protocol { tcp, udp, icmp } counter accept
						ip saddr 10.200.0.7 ip daddr { 10.0.0.132 } ip protocol tcp counter accept
					}
					chain forward {
						type filter hook forward priority 0;
						ct state {established, related} accept
						#iifname wg0 oifname wg0 counter accept
						iifname "wg0" oifname "wg0" jump forward-wg
						counter drop
					}
				}
			'';
		};
    nat = {
      enable = true;
      internalInterfaces = [ "br0" ];
      externalInterface = "eth0";
		};
  };

  containers = {
    public-ssh = {
      autoStart = true;
      privateNetwork = true;
      hostBridge = "br0";
      localAddress = "10.10.0.2/24";
      config = { config, pkgs, ... }: {

        system.stateVersion = "23.11";

				users.users.goeranh = {
					isNormalUser = true;
				};
				services.openssh.enable = true;
				environment.systemPackages = with pkgs; [
				  htop
			  ];

        networking = {
          defaultGateway.address = "10.10.0.1";
          firewall = {
            enable = true;
            allowedTCPPorts = [ 22 ];
          };
        };

        environment.etc."resolv.conf".text = "nameserver 8.8.8.8";
      };
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
              wireguardPeerConfig = {
                PublicKey = "fyJDrrVSaU6ZBsYY19FPT++PPwX8Muyw9wkA+YxoET0=";
                AllowedIPs = [ "10.200.0.2" ];
              };
            }
            {
              # workstation
              wireguardPeerConfig = {
                PublicKey = "Y76XADOksxcVc8oooxjOHgW4M1aPckMoMV4K844BYBw=";
                AllowedIPs = [ "10.200.0.3" ];
              };
            }
            {
              # pitest
              wireguardPeerConfig = {
                PublicKey = "F4yaZ9zabNpQSpV+fXAvla6klsv6SppG3Ic3IMlAxnE=";
                AllowedIPs = [ "10.200.0.4" ];
              };
            }
            {
              # nixfw
              wireguardPeerConfig = {
                PublicKey = "gmCG/K+cVYNdz9R7raBcU+OpGF+lQ9ClCGhfbC3THmY=";
                AllowedIPs = [ "10.200.0.5" "10.0.0.0/24" "10.0.1.0/24" "10.16.17.0/21" ];
              };
            }
            {
              # iphone 6
              wireguardPeerConfig = {
                PublicKey = "37dTDJ0/ThwTvJLHDzPSHq7bERSREAgnhCIgKAhc4Qc=";
                AllowedIPs = [ "10.200.0.6" ];
              };
            }
            {
              # iphone 13
              wireguardPeerConfig = {
                PublicKey = "KvqfWEJYeBSQfPZ5c9J57izdG6HQ8rLWLaeINf0nHk4=";
                AllowedIPs = [ "10.200.0.7" ];
              };
            }
            {
              # pi5
              wireguardPeerConfig = {
                PublicKey = "h6IOeJC8u5ASiXkLkylrHgGrlYc2xdBnwsVg5SX59FQ=";
                AllowedIPs = [ "10.200.0.8" ];
              };
            }
            {
              # kbuild
              wireguardPeerConfig = {
                PublicKey = "o9QBwnoCsK2LV1b0ppjbKlRZMoE8Z73a6uAfsoq/T3o==";
                AllowedIPs = [ "10.200.0.9" ];
              };
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
          address = [ "10.200.0.1/24" ];
          networkConfig = {
            IPMasquerade = "ipv4";
            IPForward = true;
          };
					routingPolicyRules = [
						{
							routingPolicyRuleConfig = {
								Family = "ipv4";
								From = "10.200.0.0/24";
								To = "10.0.0.0/23";
								Table = "wg-blade";
							};
						}
						{
							routingPolicyRuleConfig = {
								Family = "ipv4";
								From = "10.200.0.0/24";
								To = "10.200.0.0/24";
								Table = "wg-wg";
							};
						}
					];
          routes = [
					  {
							routeConfig = {
								Gateway = "10.200.0.5";
								Destination = "10.0.0.0/23";
								Table = "wg-blade";
							};
						}
					  {
							routeConfig = {
								Gateway = "10.200.0.1";
								Destination = "10.200.0.0/24";
								Table = "wg-wg";
							};
						}
					];
        };
        "eth0" = {
          matchConfig.Name = "eth0";
          address = [
            "2a01:4f8:c013:27a4::1"
          ];
          DHCP = "yes";
          networkConfig = {
            IPv6AcceptRA = false;
          };
        };
        "40-br0" = {
          matchConfig.Name = "br0";
          bridgeConfig = { };
          networkConfig.LinkLocalAddressing = "no";
          address = [
            "10.20.0.1/24"
          ];
          networkConfig = {
            ConfigureWithoutCarrier = true;
          };
        };
      };
    };
  };
}
