{ inputs, lib, self }:

let
  # all the input flakes for `nix copy` to the build machine,
  # to be available for --override-input
  inputPaths = lib.escapeShellArgs (builtins.attrValues inputs);
  overrideInputsArgs = lib.concatStringsSep " " (builtins.attrValues (lib.mapAttrs
    (name: value: "--override-input ${name} ${value}")
    (lib.filterAttrs (name: _value: name != "self") inputs)
  ));
in
lib.attrsets.mapAttrs
  (system: pkgs:
  pkgs //
  {
    #list-upgradable = pkgs.writeScriptBin "list-upgradable" ''
    #  #! ${pkgs.runtimeShell}

    #  NORMAL="\033[0m"
    #  RED="\033[0;31m"
    #  YELLOW="\033[0;33m"
    #  GREEN="\033[0;32m"

    #  ${pkgs.lib.concatMapStringsSep "\n" (name:
    #    let
    #      addr = getHostAddr name;
    #    in lib.optionalString (addr != null) ''
    #      echo -n -e "${name}: $RED"
    #      RUNNING=$(ssh -o PreferredAuthentications=publickey -o StrictHostKeyChecking=accept-new root@"${addr}" "readlink /run/current-system")
    #      if [ $? = 0 ] && [ -n "$RUNNING" ]; then
    #        CURRENT=$(nix eval --raw ".#nixosConfigurations.${name}.config.system.build.toplevel" 2>/dev/null)
    #        RUNNING_VER=$(basename $RUNNING|rev|cut -d - -f 1|rev)
    #        RUNNING_DATE=$(echo $RUNNING_VER|cut -d . -f 3)
    #        CURRENT_VER=$(basename $CURRENT|rev|cut -d - -f 1|rev)
    #        CURRENT_DATE=$(echo $CURRENT_VER|cut -d . -f 3)

    #        if [ "$RUNNING" = "$CURRENT" ]; then
    #          echo -e "$GREEN"current"$NORMAL $RUNNING_VER"
    #        elif [ $RUNNING_DATE -gt $CURRENT_DATE ]; then
    #          echo -e "$GREEN"newer"$NORMAL $RUNNING_VER > $CURRENT_VER"
    #        elif [ "$RUNNING_VER" = "$CURRENT_VER" ]; then
    #          echo -e "$YELLOW"modified"$NORMAL $RUNNING_VER"
    #        elif [ -n "$RUNNING_VER" ]; then
    #          echo -e "$RED"outdated"$NORMAL $RUNNING_VER < $CURRENT_VER"
    #        else
    #          echo -e "$RED"error"$NORMAL $RUNNING_VER"
    #        fi
    #      fi
    #      echo -n -e "$NORMAL"
    #    '') (builtins.attrNames self.nixosConfigurations)}
    #'';

  } //
  builtins.foldl'
    (result: name:
      let
        hostConfig = self.nixosConfigurations."${name}".config;
        host = hostConfig.networking.hostName;
        target = ''root@"${host}"'';
        rebuildArg = "--flake ${self}#${name} ${overrideInputsArgs} --accept-flake-config";
        # let /var/lib/microvm/*/flake point to the flake-update branch so that
        # `microvm -u $NAME` updates to what hydra built today.
        selfRef = "git+https://gitea.c3d2.de/c3d2/nix-config?ref=flake-update";
      in
      result // {
        # Generate a small script for copying this flake to the
        # remote machine and bulding and switching there.
        # Can be run with `nix run c3d2#…-nixos-rebuild switch`
        "${name}-nixos-rebuild" = pkgs.writeScriptBin "${name}-nixos-rebuild" ''
          #!${pkgs.runtimeShell} -e

          [[ $(ssh ${target} cat /etc/hostname) == ${name} ]]
          nix copy --no-check-sigs --to ssh-ng://${target} ${inputPaths}

          # use nixos-rebuild from target config
          nixosRebuild=$(nix build ${self}#nixosConfigurations.${name}.config.system.build.nixos-rebuild ${overrideInputsArgs} --no-link --json | ${pkgs.jq}/bin/jq -r '.[0].outputs.out')
          nix copy --no-check-sigs --to ssh-ng://${target} $nixosRebuild
          ssh ${target} $nixosRebuild/bin/nixos-rebuild ${rebuildArg} "$@"
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
  self.legacyPackages
