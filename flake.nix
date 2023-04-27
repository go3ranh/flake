{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "flake:nixpkgs/nixos-unstable";
  };
  outputs = {self, nixpkgs}@inputs:
  {
    nixosConfigurations = {
	  build = nixpkgs.lib.nixosSystem {
	    system = "x86_64-linux";
	    modules = [
	      (import ./host/build)
	    ];
	  };
	  desktop = nixpkgs.lib.nixosSystem {
	    system = "x86_64-linux";
	    modules = [
	      (import ./host/desktop)
	    ];
	  };
	};
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
