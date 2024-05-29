{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-schemas.url = "github:DeterminateSystems/flake-schemas";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, nixos-generators, flake-schemas, nixos-hardware, disko, sops-nix }@inputs:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      pkgsarm64 = nixpkgs.legacyPackages.aarch64-linux;
      lib = nixpkgs.lib;
    in
    {
      nixosModules = {
        goeranh = import ./modules/goeranh.nix;
      };
      nixosConfigurations = {
        pitest = lib.nixosSystem rec {
          system = "aarch64-linux";
          modules = [
            (import ./modules/goeranh.nix { inherit self inputs lib nixpkgs; arch = system; config = self.nixosConfigurations.pitest.config; })
            (import ./host/pitest/default.nix { inherit lib inputs; config = self.nixosConfigurations.pitest.config; pkgs = pkgsarm64; })
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
            sops-nix.nixosModules.sops
          ];
        };
      } // builtins.foldl'
        (result: name: result // {
          "${name}" = lib.nixosSystem rec {
            system = "x86_64-linux";
            modules = [
              ./host/${name}
              sops-nix.nixosModules.sops
              (import ./modules/goeranh.nix { inherit self inputs lib nixpkgs; arch = system; config = self.nixosConfigurations.${name}.config; })
            ];
          };
        })
        { } [
        "dockerhost"
        "kbuild"
        "node5"
        "nixfw"
        "workstation"
        #"desktop"
      ] // builtins.foldl'
        (result: name: result // {
          "${name}" = lib.nixosSystem rec {
            system = "x86_64-linux";
            modules = [
              ./host/${name}
              sops-nix.nixosModules.sops
              disko.nixosModules.disko
              (import ./modules/goeranh.nix { inherit self inputs lib nixpkgs; arch = system; config = self.nixosConfigurations.${name}.config; })
              {
                boot = {
                  initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
                  kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
                  loader.systemd-boot.enable = true;
                };

                security.sudo.wheelNeedsPassword = false;
                system.stateVersion = "23.11";
              }
            ];
          };
        })
        { } [
        "forgejo"
        "git-website"
        "git"
        "hetzner-wg"
        "hydra"
        "kanidm"
        "monitoring"
        "nixfw2"
        "nixtesthost"
        "vaultwarden"
      ];
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;

      packages.x86_64-linux = import ./packages.nix { inherit inputs lib self; archpkgs = pkgs; };
      packages.aarch64-linux = import ./packages.nix { inherit inputs lib self; archpkgs = pkgsarm64; };

      devShells = {
        x86_64-linux = {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              sops
              ssh-to-age
            ] ++ (with self.packages.x86_64-linux; [
              updateAll
            ]);
          };
          phpshell = pkgs.mkShell {
            buildInputs = with pkgs; [
              php82
              php82Extensions.pdo_mysql
              php82Extensions.mysqli
              php82Extensions.gd
              php82Extensions.mbstring
              php82Packages.composer
            ];
          };
        };
      };
    };
}
