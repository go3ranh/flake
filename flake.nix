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
            (import ./host/pitest/default.nix { inherit lib; config = self.nixosConfigurations.pitest.config; pkgs = pkgsarm64; })
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
            sops-nix.nixosModules.sops
          ];
        };
        desktop = lib.nixosSystem rec {
          system = "x86_64-linux";
          modules = [
            ./host/desktop
            sops-nix.nixosModules.sops
            (import ./modules/goeranh.nix { inherit self inputs lib nixpkgs; arch = system; config = self.nixosConfigurations.desktop.config; })
          ];
        };
        node5 = lib.nixosSystem rec {
          system = "x86_64-linux";
          modules = [
            ./host/node5
            sops-nix.nixosModules.sops
            (import ./modules/goeranh.nix { inherit self inputs lib nixpkgs; arch = system; config = self.nixosConfigurations.node5.config; })
          ];
        };
        workstation = lib.nixosSystem rec {
          system = "x86_64-linux";
          modules = [
            ./host/workstation
            sops-nix.nixosModules.sops
            (import ./modules/goeranh.nix { inherit self inputs lib nixpkgs; arch = system; config = self.nixosConfigurations.workstation.config; })
          ];
        };
        hostingfw = lib.nixosSystem rec {
          system = "x86_64-linux";
          modules = [
            ./host/hostingfw
            sops-nix.nixosModules.sops
            (import ./modules/goeranh.nix { inherit self inputs lib nixpkgs; arch = system; config = self.nixosConfigurations.kbuild.config; })
          ];
        };
        kbuild = lib.nixosSystem rec {
          system = "x86_64-linux";
          modules = [
            ./host/kbuild
            sops-nix.nixosModules.sops
            (import ./modules/goeranh.nix { inherit self inputs lib nixpkgs; arch = system; config = self.nixosConfigurations.kbuild.config; })
          ];
        };
      };
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;

      packages.x86_64-linux = import ./packages.nix { inputs = inputs; lib = lib; self = self; archpkgs = pkgs; };
      packages.aarch64-linux = import ./packages.nix { inputs = inputs; lib = lib; self = self; archpkgs = pkgsarm64; };

      devShells = {
        x86_64-linux = {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              sops
              ssh-to-age
            ];
          };
          loraflash = pkgs.mkShell {
            buildInputs = with pkgs; [
              python3
              esptool
            ];
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
          rustshell = pkgs.mkShell {
            buildInputs = with pkgs; [
              cargo
              rustc
              gef
            ];
          };
          cshell = pkgs.mkShell {
            buildInputs = with pkgs; [
              clang
              clang-tools
              cmake
              gcc
              gef
            ];
          };
          vmshell = pkgs.mkShell {
            buildInputs = with pkgs; [
              nixos-shell
            ];
          };
        };
      };
    };
}
