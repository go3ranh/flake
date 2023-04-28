{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "flake:nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs }@inputs:
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
      packages.x86_64-linux.test = nixpkgs.legacyPackages.x86_64-linux.writeShellScriptBin "test" ''
        	'';
      #packages = inputs.nixpkgs.lib.attrsets.mapAttrs
      #  ((system: pkgs:
      #    {
      #	  #"${system}-test" =
      #	  "${system}-test" = pkgs.writeShellScriptBin "${system}-test" ''
      #		echo "test"
      #	  '';
      #	}
      #  ) (builtins.getAttr self.nixosConfigurations));
    };
}
