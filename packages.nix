{ inputs, pkgs, lib, self }:
builtins.foldl'
  (result: name:
    let
      cfg = self.nixosConfigurations.${name};
      target =
        if cfg ? _module.args.nixinate.host then
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
  // {
  settings = pkgs.stdenv.mkDerivation rec {
    buildInputs = [ pkgs.fzf ];
    name = "settings";
    description = "goeranh settings / dotfiles";
    bashrc = pkgs.writeText ".bashrc" ''
            source "${inputs.nixpkgs.legacyPackages.x86_64-linux.fzf.outPath}/share/fzf/key-bindings.bash"
            source "${inputs.nixpkgs.legacyPackages.x86_64-linux.fzf.outPath}/share/fzf/completion.bash"
            function pkgsearch (){
            nix-env -qa | fzf
            }

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

    goeranh = pkgs.writeText ".goeranh" ''
      alias :q="exit"
      alias :Q="exit"
      alias tml="tmux ls"
      alias nsh="nix-shell -p"
      alias tma="tmux ls && tmux a || tmux"
      alias ccat="/bin/cat"
      alias cat="bat"
      alias ls="exa"
      alias lls="/bin/ls --color"
      alias gits="git status"
      alias gitd="git diff"
      alias gita="git add"
      alias gitc="git commit -m"
      alias todos="todo s"
      alias catsh="cat --file-name=\"temp.sh\""
      alias catml="cat --file-name=\"temp.html\""
      alias ifconfig="ip a"
      alias vim="nvim"
      alias nixrevisions="sudo nix-env --list-generations --profile /nix/var/nix/profiles/system"
      alias ng="./node_modules/@angular/cli/bin/ng.js"
      #alias nyxt="/home/goeranh/programs/nyxt/usr/local/bin/nyxt"
      export EDITOR="vim"

      [ -f ~/.fzf.bash ] && source ~/.fzf.bash

      function ghssh(){
          TEST=$(ping -c 1 -w 1 192.168.178.62)
          retval=$?
          if [ $retval -eq 0 ]; then
              ssh 192.168.178.62 "$@"
          else
              ssh goeranh.de "$@"
          fi
      }
      alias sshgh="ghssh"

      #open tmux session with pwd as session name
      function tmn (){
          name=$(pwd | awk -F'/' '{print $NF}')
          tmux new -s $name
      }

      function zn (){
          name=$(pwd | awk -F'/' '{print $NF}')
          zellij -s $name
      }

      #launch tor
      function torlaunch(){
          cd /home/goeranh/programs/tor-browser_en-US
          ./start-tor-browser.desktop
      }

      #push to all remotes in this repo
      function gitpa (){
          branch="master"
          if [ $# -gt 0 ]; then
              branch=$1
          fi
          for remote in $(git remote); do
              echo $remote
              git push $remote $branch
          done
      }

      function sturaproxy(){
          flatpak run org.mozilla.firefox &
          echo "connecting ssh"
          ssh -p 1005 administration@141.56.51.250 -D 9090 -N
      }

      function checklogins(){
          ips="10.1.0.17 10.1.0.31 10.1.0.32 10.1.0.33 10.1.0.51"

          for ip in $ips; do
              result=$(ssh $ip "w -h")
              num=$(echo "$result" | wc -l)
              if [ $num -gt 1 ]; then
                  echo "$result"
              fi
          done

      }

      function sshpf(){
        if [ $# -ne 1 ]; then
          echo "please provide a hostname or ip"
          exit 1
        fi
        firefox -p proxy &
        ssh -ND 9090 $1
      }
    '';

    nvimconfig = builtins.fetchGit {
      url = "https://gitlab.goeranh.de/goeranh/nvim-config.git";
      rev = "ee8604deb04b4b555ab0504e92200ab94ef8d497";
    };

    postInstall = ''
      	  mkdir -p $out
      	  cp $bashrc $out/.bashrc
      	  cp $goeranh $out/.goeranh
      	  cp -r $nvimconfig $out/nvim-config
      	'';

    src = ./.;
  };
}
