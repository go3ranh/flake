{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable?b0d36bd0a420ecee3bc916c91886caca87c894e9";
    flake-schemas.url = "github:DeterminateSystems/flake-schemas";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, nixpkgs-unstable, nixos-generators, flake-schemas, hyprland, nixos-hardware, disko, sops-nix }@inputs:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      pkgsx86 = nixpkgs.legacyPackages.x86_64-linux;
      pkgsarm64 = nixpkgs.legacyPackages.aarch64-linux;
      lib = nixpkgs.lib;
    in
    {
      nixosModules = {
        goeranh = import ./modules/goeranh.nix;
      };
      nixosConfigurations = {
        bootstrap = lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            self.nixosModules.goeranh
            sops-nix.nixosModules.sops
            disko.nixosModules.disko
            "${nixpkgs}/nixos/modules/installer/cd-dvd/iso-image.nix"
            "${nixpkgs}/nixos/modules/virtualisation/proxmox-lxc.nix"
            {
              config = {
                goeranh = {
                  server = true;
                };
                system.stateVersion = "23.05";
              };
            }
          ];
        };
        pitest = lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            (import ./host/pitest/default.nix { config = self.nixosConfigurations.pitest.config; pkgs = pkgsarm64; pkgs-unstable = nixpkgs-unstable.legacyPackages.aarch64-linux; lib = nixpkgs.lib; })
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
            sops-nix.nixosModules.sops
            self.nixosModules.goeranh
            {
              environment.systemPackages = [
                self.packages.aarch64-linux.customvim
              ];
              programs.bash.interactiveShellInit = ''
                source ${self.packages.aarch64-linux.settings.bashrc.outPath}
                source ${self.packages.aarch64-linux.settings.goeranh.outPath}
              '';
            }
          ];
        };
        desktop = lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./host/desktop
            self.nixosModules.goeranh
            sops-nix.nixosModules.sops
            {
              programs.bash.interactiveShellInit = ''
                source ${self.packages.x86_64-linux.settings.bashrc.outPath}
                source ${self.packages.x86_64-linux.settings.goeranh.outPath}
              '';
            }
          ];
        };
        node5 = lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./host/node5
            {
              environment.systemPackages = [
                self.packages.x86_64-linux.proxmark
                self.packages.x86_64-linux.customvim
              ];
              programs = {
                bash.interactiveShellInit = ''
                  source ${self.packages.x86_64-linux.settings.bashrc.outPath}
                  source ${self.packages.x86_64-linux.settings.goeranh.outPath}
                '';
              };
            }
            sops-nix.nixosModules.sops
            self.nixosModules.goeranh
          ];
        };
        nixserver = lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./host/nixserver
            sops-nix.nixosModules.sops
            {
              programs = {
                bash.interactiveShellInit = ''
                  source ${self.packages.x86_64-linux.settings.bashrc.outPath}
                  source ${self.packages.x86_64-linux.settings.goeranh.outPath}
                '';
              };
            }
            self.nixosModules.goeranh
          ];
        };
        workstation = lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./host/workstation
            sops-nix.nixosModules.sops
            {
              environment.systemPackages = [
                self.packages.aarch64-linux.customvim
              ];
              programs.bash.interactiveShellInit = ''
								source ${self.packages.x86_64-linux.settings.bashrc.outPath}
								source ${self.packages.x86_64-linux.settings.goeranh.outPath}
              '';
            }
            self.nixosModules.goeranh
          ];
        };
        kbuild = lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./host/kbuild
            sops-nix.nixosModules.sops
            {
              programs = {
                bash.interactiveShellInit = ''
                  source ${self.packages.x86_64-linux.settings.bashrc.outPath}
                  source ${self.packages.x86_64-linux.settings.goeranh.outPath}
                '';
              };
            }
            self.nixosModules.goeranh
          ];
        };
        # hetznertest = lib.nixosSystem {
        #   system = "x86_64-linux";
        #   modules = [
        #     ./host/hetznertest
        #     sops-nix.nixosModules.sops
        #     {
        #       programs = {
        #         bash.interactiveShellInit = ''
        #           source ${self.packages.x86_64-linux.settings.bashrc.outPath}
        #           source ${self.packages.x86_64-linux.settings.goeranh.outPath}
        #         '';
        #       };
        #     }
        #     self.nixosModules.goeranh
        #   ];
        # };
        deploy-iso = lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            "${nixpkgs}/nixos/modules/installer/cd-dvd/iso-image.nix"
            #./host/deployment
            sops-nix.nixosModules.sops
            {
              programs = {
                bash.interactiveShellInit = ''
                  source ${self.packages.x86_64-linux.settings.bashrc.outPath}
                  source ${self.packages.x86_64-linux.settings.goeranh.outPath}
                '';
              };
            }
            self.nixosModules.goeranh
          ];
        };
      };
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
      #hydraJobs =
      #  nixpkgs.lib.mapAttrs (_: nixpkgs.lib.hydraJob)
      #    (
      #      let
      #        getBuildEntryPoint = _: nixosSystem:
      #          nixosSystem.config.system.build.toplevel;
      #      in
      #      nixpkgs.lib.mapAttrs getBuildEntryPoint self.nixosConfigurations
      #    );

      packages.x86_64-linux = import ./packages.nix { inputs = inputs; lib = lib; self = self; archpkgs = pkgsx86; };
      packages.aarch64-linux = import ./packages.nix { inputs = inputs; lib = lib; self = self; archpkgs = pkgsarm64; };
      #bootstrap = nixos-generators.nixosGenerate {
      #  system = "x86_64-linux";
      #  modules = [
      #    self.nixosConfigurations.bootstrap.config
      #    {
      #      users.users.root.password = "test";
      #    }
      #  ];
      #  format = "proxmox-lxc";
      #};

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
