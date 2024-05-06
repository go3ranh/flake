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
    netbird = false;
    server = true;
    update = true;
    monitoring = false;
  };

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
    firewall.allowedUDPPorts = [ 51820 ];
    firewall.enable = lib.mkForce false;
    usePredictableInterfaceNames = false;

		nftables = {
			ruleset = ''
			  table inet filter {
					counter wireguard-udp {}
					counter node5-traffic {}
					counter node5-ping {}
					counter node5-forward-traffic {}
					counter node5-forward-ping {}
					counter drop-input {}
					chain input {
						type filter hook input priority 0;
						iifname lo accept
						ct state {established, related} accept
						# allow wireguard traffic
						ip daddr 49.13.134.146 udp dport { 51820 } counter name wireguard-udp accept
						# ip daddr 49.13.134.146 tcp dport { 22 } counter name public-ssh accept
						ip saddr { 10.200.0.2 } ip protocol icmp icmp type { destination-unreachable, router-advertisement, time-exceeded, parameter-problem, echo-request } counter name node5-ping accept
						ip saddr { 10.200.0.2 } tcp dport { 22, 80, 443 } counter name node5-traffic accept

						counter name drop-input drop
					}

					chain output {
						type filter hook output priority 0;
						accept
					}

					chain forward {
						type filter hook forward priority 0;
						ct state {established, related} accept
						#iifname wg0 oifname wg0 counter accept
						ip saddr 10.200.0.2 ip daddr { 10.200.0.0/24, 10.0.0.0/24, 10.0.1.0/24 } tcp dport { 22, 80, 443 } counter name node5-forward-traffic accept
						ip saddr 10.200.0.2 ip daddr { 10.200.0.0/24, 10.0.0.0/24, 10.0.1.0/24 } ip protocol icmp counter name node5-forward-ping accept
						counter drop
					}
				}
			'';
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
      netdevs = {
        "50-wg0" = {
          netdevConfig = {
            Kind = "wireguard";
            Name = "wg0";
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
                PublicKey = "fyJDrrVSaU6ZBsYY19FPT++PPwX8Muyw9wkA+YxoET0=";
                AllowedIPs = [ "10.200.0.2" ];
              };
            }
            {
              # fedora vm
              wireguardPeerConfig = {
                PublicKey = "D0QJSN9zM1lxNsfrgYVA5DVyE6woz5U27kqQpQF13CQ=";
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
          ];
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
          routes = [
					  {
							routeConfig = {
								Gateway = "10.200.0.5";
								Destination = "10.0.0.0/24";
							};
						}
					  {
							routeConfig = {
								Gateway = "10.200.0.5";
								Destination = "10.0.1.0/24";
							};
						}
					  {
							routeConfig = {
								Gateway = "10.200.0.5";
								Destination = "10.16.17.0/21";
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
      };
    };
  };
}
