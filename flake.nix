{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "flake:nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs }@inputs:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      lib = nixpkgs.lib;
    in
    {
      nixosModules = {
        goeranh = import ./modules/goeranh.nix;
      };
      nixosConfigurations = {
        build = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./host/build
          ];
        };
        desktop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./host/desktop
            self.nixosModules.goeranh
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

      legacyPackages = nixpkgs.legacyPackages;
      packages = import ./packages.nix { inherit inputs lib self; };
    };
}
