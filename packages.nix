{ inputs, lib, self, archpkgs, ... }@input: builtins.foldl'
  (result: name:
    let
      cfg = self.nixosConfigurations.${name}.config;
      target = cfg.networking.hostName;
    in
    result // (if cfg.goeranh.update then {
      "${name}-update" = archpkgs.writeScriptBin "${name}-update" ''
                #!${archpkgs.runtimeShell} -e

        			  nixos-rebuild switch --flake .#${name} --target-host goeranh@${target} --use-remote-sudo
      '';
      "${name}-update-local" = archpkgs.writeScriptBin "${name}-update-local" ''
                #!${archpkgs.runtimeShell} -e

        			  nixos-rebuild switch --flake .#${name} --target-host ${cfg.goeranh.update-user}@${target} --use-remote-sudo --build-host ${cfg.goeranh.update-user}@${target}
        			'';
      "${name}-update-builder" = archpkgs.writeScriptBin "${name}-update-builder" ''
                #!${archpkgs.runtimeShell} -e

        			  nixos-rebuild switch --flake .#${name} --target-host ${cfg.goeranh.update-user}@${target} --use-remote-sudo --build-host nixserver
      '';
    } else { }))
  { }
  (builtins.attrNames self.nixosConfigurations)
  // {
  settings = archpkgs.stdenv.mkDerivation rec {
    buildInputs = with archpkgs; [ fzf bfs git ];
    name = "settings";
    description = "goeranh settings / dotfiles";
    bashrc = archpkgs.writeText ".bashrc" ''
            source "${archpkgs.fzf.outPath}/share/fzf/key-bindings.bash"
            source "${archpkgs.fzf.outPath}/share/fzf/completion.bash"
      	    source ${archpkgs.git.outPath}/share/bash-completion/completions/git
            export XDG_CONFIG_HOME="/home/goeranh/.config"
            export XDG_CONFIG_DIRS="$XDG_CONFIG_DIRS:/home/goeranh/.config"
            export GOPATH="/home/goeranh/gitprojects"


            eval "$(direnv hook bash)"
            HISTFILESIZE=100000
            HISTSIZE=10000

            shopt -s histappend
            shopt -s checkwinsize
            shopt -s extglob
            shopt -s globstar
            shopt -s checkjobs
    '';

    goeranh = archpkgs.writeText ".goeranh" ''
      alias :q="exit"
      alias :Q="exit"
      alias tml="tmux ls"
      alias tma="tmux ls && tmux a || tmux"
      alias lls="/bin/ls --color"
      alias vim="nvim"
      export EDITOR="nvim"
      alias open="xdg-open"

      #open tmux session with pwd as session name
      function tmn (){
          name=$(pwd | awk -F'/' '{print $NF}')
          tmux new -s $name
      }

      function pmlocal (){
				  ssh -L 8006:127.0.0.1:8006 -L 3128:127.0.0.1:3128 $1
      }

    '';

    dconf = archpkgs.writeShellScriptBin "apply-dconf" ''
      echo "${builtins.readFile ./dconf}" | dconf load /
    '';

    postInstall = ''
      	  mkdir -p $out
      	  cp $bashrc $out/.bashrc
      	  cp $goeranh $out/.goeranh
      	'';

    src = ./.;
  };
  proxmark = archpkgs.stdenv.mkDerivation rec {
    pname = "proxmark3-rrg";
    version = "4.16191";

    src = archpkgs.fetchFromGitHub {
      owner = "RfidResearchGroup";
      repo = "proxmark3";
      rev = "v${version}";
      sha256 = "sha256-l0aDp0s9ekUUHqkzGfVoSIf/4/GN2uiVGL/+QtKRCOs=";
    };

    nativeBuildInputs = with archpkgs; [ pkg-config gcc-arm-embedded ];
    buildInputs = with archpkgs; [ zlib bluez5 readline bzip2 openssl ];

    makeFlags = [
      "PLATFORM=PM3GENERIC"
      "PLATFORM_EXTRAS="
    ];

    installPhase = ''
      	  mkdir -p $out/misc
      	  cp -r * $out/misc
            install -Dt $out/bin client/proxmark3
            install -Dt $out/firmware bootrom/obj/bootrom.elf armsrc/obj/fullimage.elf
    '';

    meta = with lib; {
      description = "Client for proxmark3, powerful general purpose RFID tool";
      homepage = "https://rfidresearchgroup.com/";
      license = licenses.gpl2Plus;
      maintainers = with maintainers; [ nyanotech ];
    };
  };
}
