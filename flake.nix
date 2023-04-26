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
	};
	packages = let 
      inputPaths = inputs.nixpkgs.lib.escapeShellArgs (builtins.attrValues inputs);
      overrideInputsArgs = inputs.nixpkgs.lib.concatStringsSep " " (builtins.attrValues (inputs.nixpkgs.lib.mapAttrs
        (name: value: "--override-input ${name} ${value}")
        (inputs.nixpkgs.lib.filterAttrs (name: _value: name != "self") inputs)
      ));
	in inputs.nixpkgs.lib.attrsets.mapAttrs
  (system: pkgs:
  builtins.foldl'
    (result: name:
      let
        #host = getHostAddr name;
		host = "192.168.178.170";
        target = ''root@"${host}"'';
        rebuildArg = "--flake ${self}#${name} ${overrideInputsArgs} --accept-flake-config";
        hostConfig = self.nixosConfigurations."${name}".config;
        # let /var/lib/microvm/*/flake point to the flake-update branch so that
        # `microvm -u $NAME` updates to what hydra built today.
        selfRef = "git+https://gitlab.goeranh.de/goeranh/flakeathome";
      in
      result // {
        # Generate a small script for copying this flake to the
        # remote machine and bulding and switching there.
        # Can be run with `nix run c3d2#…-nixos-rebuild switch`
        "${name}-nixos-rebuild" = pkgs.writeScriptBin "${name}-nixos-rebuild" ''
          #!${pkgs.runtimeShell} -e

          if nix eval .#nixosConfigurations.${name}.config.c3d2.deployment.server &>/dev/null; then
            echo "microvms cannot be updated with nixos-rebuild. Use nix run .#microvm-update-${name}"
            exit 2
          fi

          [[ $(ssh ${target} cat /etc/hostname) == ${name} ]]
          nix copy --no-check-sigs --to ssh-ng://${target} ${inputPaths}

          # use nixos-rebuild from target config
          nixosRebuild=$(nix build ${self}#nixosConfigurations.${name}.config.system.build.nixos-rebuild ${overrideInputsArgs} --no-link --json | ${pkgs.jq}/bin/jq -r '.[0].outputs.out')
          nix copy --no-check-sigs --to ssh-ng://${target} $nixosRebuild
          ssh ${target} $nixosRebuild/bin/nixos-rebuild ${rebuildArg} "$@"
        '';

        "${name}-nixos-rebuild-hydra" = pkgs.writeScriptBin "${name}-nixos-rebuild" ''
          #!${pkgs.runtimeShell} -e
          echo Copying Flakes
          nix copy --no-check-sigs --to ssh-ng://root@hydra.serv.zentralwerk.org ${inputPaths}
          echo Building on Hydra
          ssh root@hydra.serv.zentralwerk.org -- \
            nix build -L -o /tmp/nixos-system-${name} \
            ${self}#nixosConfigurations.${name}.config.system.build.toplevel
          echo Built. Obtaining link to data
          TOPLEVEL=$(ssh root@hydra.serv.zentralwerk.org \
            readlink /tmp/nixos-system-${name})
          echo Checking target ${name}
          ssh ${target} -- bash -e <<EOF
          [[ \$(cat /etc/hostname) == ${name} ]]
          echo Copying data from Hydra to ${name}
          nix copy --from https://nix-cache.hq.c3d2.de \
            $TOPLEVEL
          echo Activation on ${name}: "$@"
          nix-env -p /nix/var/nix/profiles/system --set $TOPLEVEL
          $TOPLEVEL/bin/switch-to-configuration "$@"
          EOF
        '';

        "${name}-nixos-rebuild-local" = pkgs.writeScriptBin "${name}-nixos-rebuild" ''
          #!${pkgs.runtimeShell} -ex
          [[ $1 == build || $(ssh ${target} cat /etc/hostname) == ${name} ]]
          # don't re-execute, otherwise we run the targetPlatform locally
          _NIXOS_REBUILD_REEXEC=1 ${pkgs.nixos-rebuild}/bin/nixos-rebuild ${rebuildArg} --target-host ${target} --use-remote-sudo "$@"
        '';

        "${name}-cleanup" = pkgs.writeScriptBin "${name}-cleanup" ''
          #!${pkgs.runtimeShell} -ex
          ssh ${target} "time nix-collect-garbage -d && time nix-store --optimise"
        '';
      }) 
    { }
    (builtins.attrNames self.nixosConfigurations)

  ) 
  {};
  };
}
