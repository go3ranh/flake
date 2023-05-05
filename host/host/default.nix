{ config, pkgs, ... }:
let
  hostname = "nixhost";
  domainname = "tailf0ec0.ts.net";
in
rec {
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda";

  networking.hostName = hostname;
  networking.networkmanager.enable = true;
  networking.firewall.checkReversePath = "loose";

  time.timeZone = "Europe/Berlin";

  services = {
    postgresql = {
      authentication = ''
        local gitea all ident map=gitea-users
      '';
      identMap = ''
        gitea-users gitea gitea
      '';
    };
    hydra = {
      enable = true;
      hydraURL = "https://${hostname}.${domainname}/hydra";
      port = 3001;
      useSubstitutes = true;
      notificationSender = "goeran@karsdorf.net";
    };
    openssh = {
      enable = true;
      extraConfig = ''
                MaxAuthTries 10
        	PubkeyAuthentication yes
      '';
      #passwordAuthentication = false;
    };
    nginx = {
      enable = true;
      virtualHosts = {
        "${hostname}.${domainname}" = {
          sslCertificate = "/var/lib/nixhost.tailf0ec0.ts.net.crt";
          sslCertificateKey = "/var/lib/nixhost.tailf0ec0.ts.net.key";
          forceSSL = true;
          locations = {
            "/gitea/" = {
              proxyPass = "http://localhost:3000/";
              recommendedProxySettings = true;
            };
            "/hydra" = {
              recommendedProxySettings = true;
              proxyPass = "http://localhost:3001";
            };
          };
        };
      };
    };
    gitea = {
      enable = true;
      database = {
        type = "postgres";
      };
	  settings.server = {
        DOMAIN = "${hostname}.${domainname}";
        ROOT_URL = "https://${hostname}.${domainname}/gitea";
	  };
    };
  };

  networking.firewall.allowedTCPPorts = [ 22 80 443 3001 ];

  system.stateVersion = "22.11";

}
