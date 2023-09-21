{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "flake:nixpkgs/nixos-unstable";
    #nixpkgs-unstable.url = "flake:nixpkgs/nixos-unstable";
    flake-schemas.url = "github:DeterminateSystems/flake-schemas";
    #nixpkgs.url = "github:go3ranh/nixpkgs/invoiceplane-change-port";
    microvm = {
      url = "github:astro/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixinate = {
      url = "github:matthewcroughan/nixinate";
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
  outputs = { self, nixpkgs, flake-schemas, microvm, nixinate, hyprland, nixos-hardware, disko }@inputs:
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
      apps = nixinate.nixinate.x86_64-linux self;
      nixosConfigurations = {
        pitest = lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            ./host/pitest
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
            self.nixosModules.goeranh
            {
              environment.systemPackages = [
                self.packages.aarch64-linux.proxmark
              ];
              programs.bash.interactiveShellInit = ''
                source ${self.packages.aarch64-linux.settings.bashrc.outPath}
                source ${self.packages.aarch64-linux.settings.goeranh.outPath}
              '';
              programs.neovim.runtime."init.lua".text = lib.readFile "${self.packages.aarch64-linux.settings.nvimconfig.outPath}/nvim-config/init.lua";
                programs.neovim.configure = {
                  customRC = ''
                    dofile('${self.packages.aarch64-linux.settings.nvimconfig.outPath}/init.lua')
                  '';
                };
            }
            {
              _module.args.nixinate = {
                host = "pitest";
                sshUser = "goeranh";
                buildOn = "remote"; # valid args are "local" or "remote"
                substituteOnTarget = true; # if buildOn is "local" then it will substitute on the target, "-s"
                hermetic = false;
              };
            }
          ];
        };
        pwnzero = lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            ./host/pwnzero
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
            self.nixosModules.goeranh
            nixos-hardware.nixosModules.raspberry-pi-4
            {
              environment.systemPackages = [
                self.packages.aarch64-linux.proxmark
              ];
              programs.bash.interactiveShellInit = ''
                source ${self.packages.aarch64-linux.settings.bashrc.outPath}
                source ${self.packages.aarch64-linux.settings.goeranh.outPath}
              '';
              programs.neovim.runtime."init.lua".text = lib.readFile "${self.packages.aarch64-linux.settings.nvimconfig.outPath}/nvim-config/init.lua";
              programs.neovim.configure = {
                customRC = ''
                  dofile('${self.packages.aarch64-linux.settings.nvimconfig.outPath}/init.lua')
                '';
              };
            }
          ];
        };
        networking-test = lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            ./host/networking-test
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
            self.nixosModules.goeranh
            nixos-hardware.nixosModules.raspberry-pi-4
          ];
        };
        desktop = lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./host/desktop
            self.nixosModules.goeranh
            {
              programs.bash.interactiveShellInit = ''
                source ${self.packages.x86_64-linux.settings.bashrc.outPath}
                source ${self.packages.x86_64-linux.settings.goeranh.outPath}
              '';
            }
            {
              _module.args.nixinate = {
                host = "192.168.178.43";
                sshUser = "goeranh";
                buildOn = "remote"; # valid args are "local" or "remote"
                substituteOnTarget = true; # if buildOn is "local" then it will substitute on the target, "-s"
                hermetic = false;
              };
            }
          ];
        };
        hypr = lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./host/hypr
            self.nixosModules.goeranh
            inputs.hyprland.nixosModules.default
            {
              programs.bash.interactiveShellInit = ''
                source ${self.packages.x86_64-linux.settings.bashrc.outPath}
                source ${self.packages.x86_64-linux.settings.goeranh.outPath}
              '';
            }
            {
              _module.args.nixinate = {
                host = "192.168.122.208";
                sshUser = "goeranh";
                buildOn = "remote"; # valid args are "local" or "remote"
                substituteOnTarget = true; # if buildOn is "local" then it will substitute on the target, "-s"
                hermetic = false;
              };
            }
          ];
        };
        laptop1 = lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./host/laptop1
            self.nixosModules.goeranh
            {
              programs.bash.interactiveShellInit = ''
                source ${self.packages.x86_64-linux.settings.bashrc.outPath}
                source ${self.packages.x86_64-linux.settings.goeranh.outPath}
              '';
            }
            {
              _module.args.nixinate = {
                host = "192.168.178.158";
                sshUser = "goeranh";
                buildOn = "remote";
                substituteOnTarget = true;
                hermetic = false;
              };
            }
          ];
        };
        poweredge = lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./host/poweredge
            self.nixosModules.goeranh
            disko.nixosModules.disko
            {
              programs.bash.interactiveShellInit = ''
                source ${self.packages.x86_64-linux.settings.bashrc.outPath}
                source ${self.packages.x86_64-linux.settings.goeranh.outPath}
              '';
            }
            {
              _module.args.nixinate = {
                host = "192.168.178.123";
                sshUser = "root";
                buildOn = "remote";
                substituteOnTarget = true;
                hermetic = false;
              };
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
              ];
              programs = {
                bash.interactiveShellInit = ''
                  source ${self.packages.x86_64-linux.settings.bashrc.outPath}
                  source ${self.packages.x86_64-linux.settings.goeranh.outPath}
                '';
                neovim.configure = {
                  customRC = ''
                    dofile('${self.packages.x86_64-linux.settings.nvimconfig.outPath}/init.lua')
                  '';
                };
              };
            }
            self.nixosModules.goeranh
          ];
        };
      };
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
      #hydraJobs =
      #  nixpkgs.lib.mapAttrs (_: nixpkgs.lib.hydraJob) (
      #    let
      #      getBuildEntryPoint = _: nixosSystem:
      #        nixosSystem.config.system.build.toplevel;
      #    in
      #    nixpkgs.lib.mapAttrs getBuildEntryPoint self.nixosConfigurations
      #  );

      #legacyPackages = nixpkgs.legacyPackages;
      #packages.x86_64-linux = import ./packages.nix { inherit inputs lib self pkgsx86; };
      packages.x86_64-linux = import ./packages.nix { inputs = inputs; lib = lib; self = self; archpkgs = pkgsx86; };
      packages.aarch64-linux = import ./packages.nix { inputs = inputs; lib = lib; self = self; archpkgs = pkgsarm64; };

      devShells = {
        x86_64-linux = {
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
