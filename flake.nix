{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "flake:nixpkgs/nixos-unstable";
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
  };
  outputs = { self, nixpkgs, microvm, nixinate, hyprland, nixos-hardware }@inputs:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      lib = nixpkgs.lib;
    in
    rec {
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
            nixos-hardware.nixosModules.raspberry-pi-4
            #{
            #  programs.bash.interactiveShellInit = ''
            #    source ${packages.x86_64-linux.settings.bashrc.outPath}
            #    source ${packages.x86_64-linux.settings.goeranh.outPath}
            #  '';
            #}
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
                source ${packages.x86_64-linux.settings.bashrc.outPath}
                source ${packages.x86_64-linux.settings.goeranh.outPath}
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
                source ${packages.x86_64-linux.settings.bashrc.outPath}
                source ${packages.x86_64-linux.settings.goeranh.outPath}
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
                source ${packages.x86_64-linux.settings.bashrc.outPath}
                source ${packages.x86_64-linux.settings.goeranh.outPath}
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
        node5 = lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./host/node5
            {
              programs = {
                bash.interactiveShellInit = ''
                  source ${packages.x86_64-linux.settings.bashrc.outPath}
                  source ${packages.x86_64-linux.settings.goeranh.outPath}
                '';
                neovim.configure = {
                  customRC = ''
                    dofile('${packages.x86_64-linux.settings.nvimconfig.outPath}/init.lua')
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
      packages.x86_64-linux = import ./packages.nix { inherit inputs pkgs lib self; };

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
