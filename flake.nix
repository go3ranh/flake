{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "flake:nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "flake:nixpkgs/nixos-23.05";
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
  outputs = { self, nixpkgs, nixpkgs-stable, nixos-generators, flake-schemas, hyprland, nixos-hardware, disko, sops-nix }@inputs:
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
        #bootstrap = lib.nixosSystem {
        #  system = "aarch64-linux";
        #  modules = [
        #    self.nixosModules.goeranh
        #    {
        #      config = {
        #        goeranh = {
        #          server = true;
        #        };
        #      };
        #    }
        #  ];
        #};
        pitest = lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            ./host/pitest
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
            sops-nix.nixosModules.sops
            self.nixosModules.goeranh
            {
              environment.systemPackages = [
                self.packages.aarch64-linux.proxmark
                self.packages.aarch64-linux.customvim
              ];
              programs.bash.interactiveShellInit = ''
                source ${self.packages.aarch64-linux.settings.bashrc.outPath}
                source ${self.packages.aarch64-linux.settings.goeranh.outPath}
              '';
            }
          ];
        };
        sdrpi = lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            ./host/sdrpi
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
            sops-nix.nixosModules.sops
            self.nixosModules.goeranh
            {
              environment.systemPackages = [
                self.packages.aarch64-linux.proxmark
              ];
              programs.bash.interactiveShellInit = ''
                source ${self.packages.aarch64-linux.settings.bashrc.outPath}
                source ${self.packages.aarch64-linux.settings.goeranh.outPath}
              '';
            }
          ];
        };
        pwnzero = lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            ./host/pwnzero
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
            self.nixosModules.goeranh
            sops-nix.nixosModules.sops
            nixos-hardware.nixosModules.raspberry-pi-4
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
            sops-nix.nixosModules.sops
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
            disko.nixosModules.disko
          ];
        };
        kdeploy = lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./host/kdeploy
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
            disko.nixosModules.disko
          ];
        };
        hetznertest = lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./host/hetznertest
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
            disko.nixosModules.disko
          ];
        };
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
            disko.nixosModules.disko
          ];
        };
        #testkernel = lib.nixosSystem {
        #  system = "x86_64-linux";
        #  modules = [
        #    self.nixosModules.goeranh
        #    sops-nix.nixosModules.sops
        #    {
        #      fileSystems."/" =
        #        {
        #          device = "/dev/sda";
        #          fsType = "ext4";
        #        };
        #      boot.loader.grub.devices = [ "/dev/sda" ];
        #      boot.kernelPatches = [{
        #        name = "crashdump-config";
        #        patch = null;
        #        extraConfig = ''
        #          CRASH_DUMP y
        #          DEBUG_INFO y
        #          PROC_VMCORE y
        #          LOCKUP_DETECTOR y
        #          HARDLOCKUP_DETECTOR y
        #        '';
        #      }];
        #    }

        #  ];
        #};
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
