{ inputs, pkgs, lib, self }:
  builtins.foldl'
    (result: name:
      let 
        cfg = self.nixosConfigurations.${name};
        target = if cfg ? _module.args.nixinate.host then
          cfg._module.args.nixinate.host
        else
          name;
      in
      result // {
        # Generate a small script for copying this flake to the
        # remote machine and bulding and switching there.
        # Can be run with `nix run c3d2#…-nixos-rebuild switch`
        "${name}-ssh" = pkgs.writeScriptBin "${name}-ssh" ''
          #!${pkgs.runtimeShell} -e

          ssh ${target}
        '';

        "${name}-ssh-A" = pkgs.writeScriptBin "${name}-ssh" ''
          #!${pkgs.runtimeShell} -e

          ssh ${target} -A
        '';
      })
    { }
    (builtins.attrNames self.nixosConfigurations)
