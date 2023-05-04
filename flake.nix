{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "flake:nixpkgs/nixos-unstable";
    nixinate = {
      url = "github:matthewcroughan/nixinate";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, nixinate }@inputs:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      lib = nixpkgs.lib;
    in
    {
      nixosModules = {
        goeranh = import ./modules/goeranh.nix;
      };
      apps = nixinate.nixinate.x86_64-linux self;
      nixosConfigurations = {
        build = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./host/build
            {
              _module.args.nixinate = {
                host = "nixbuild";
                sshUser = "goeranh";
                buildOn = "remote";
                substituteOnTarget = true;
                hermetic = false;
              };
            }
          ];
        };
        desktop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./host/desktop
            self.nixosModules.goeranh
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
        laptop1 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./host/laptop1
            self.nixosModules.goeranh
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
        node5 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./host/node5
            self.nixosModules.goeranh
          ];
        };
      };
      formatter.x86_64-linux = inputs.nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;

      #legacyPackages = nixpkgs.legacyPackages;
      #packages = import ./packages.nix { inherit inputs lib self; };
    };
}
