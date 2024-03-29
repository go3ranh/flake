{ inputs, lib, self, archpkgs, ... }@input: {
  customvim = archpkgs.neovim.override {
    vimAlias = true;
    configure =
      let
        plugins = with archpkgs.vimPlugins; [
          nvim-treesitter-parsers.sql
          nvim-treesitter-parsers.typescript
          nvim-treesitter-parsers.arduino
          nvim-treesitter-parsers.c
          nvim-treesitter-parsers.cmake
          nvim-treesitter-parsers.cpp
          nvim-treesitter-parsers.css
          nvim-treesitter-parsers.csv
          nvim-treesitter-parsers.dockerfile
          nvim-treesitter-parsers.elixir
          nvim-treesitter-parsers.gitcommit
          nvim-treesitter-parsers.git_config
          nvim-treesitter-parsers.gitignore
          nvim-treesitter-parsers.git_rebase
          nvim-treesitter-parsers.go
          nvim-treesitter-parsers.html
          nvim-treesitter-parsers.java
          nvim-treesitter-parsers.javascript
          nvim-treesitter-parsers.json
          nvim-treesitter-parsers.latex
          nvim-treesitter-parsers.markdown
          nvim-treesitter-parsers.nix
          nvim-treesitter-parsers.org
          nvim-treesitter-parsers.php
          nvim-treesitter-parsers.sql
          nvim-treesitter-parsers.ssh_config

          plenary-nvim
          telescope-nvim

          vim-dadbod
          vim-dadbod-ui
          vim-dadbod-completion

          vim-fugitive

          nvim-lspconfig
          nvim-cmp
          cmp-buffer
          cmp-path
          cmp-nvim-tags
          cmp-treesitter
          phpactor

          orgmode

          vim-floaterm
          nvim-tree-lua
          undotree
        ];

        pack = archpkgs.pkgs.linkFarm "neovim-plugins"
          (map
            (pkg:
              {
                name = "pack/${pkg.name}/start/${pkg.name}";
                path = toString pkg;
              })
            plugins);
        vimpkgs = archpkgs.vimPlugins;
        luaconfig = archpkgs.writeText "init.lua" ''
                    vim.opt.packpath = '${pack}/'
                    vim.opt.number = true
                    vim.opt.relativenumber = true
                    vim.opt.tabstop = 4
                    vim.opt.softtabstop = 4
                    vim.opt.shiftwidth = 4
                    vim.opt.smartindent = true
                    vim.opt.swapfile = false
                    vim.opt.backup = false
                    vim.opt.hlsearch = false
                    vim.opt.incsearch = true
                    vim.opt.termguicolors = true
                    vim.opt.scrolloff = 5
                    vim.opt.undodir = vim.env.HOME .. '/.vim/undodir'
          
                    vim.g.mapleader = " ";
                    vim.cmd 'colorscheme slate'
                    -- vim.cmd 'colorscheme dracula'
          
                    local builtin = require('telescope.builtin')
          
                    local cmp = require('cmp')
                    cmp.setup {
                    	sources = {
                    		{ name = 'treesitter' },
                    		{ name = 'buffer' },
                    		{ name = 'path' }
                    	}
                    }
          
                    require'lspconfig'.phpactor.setup{
                    		on_attach = on_attach,
                    		init_options = {
                    				["language_server_phpstan.enabled"] = false,
                    				["language_server_psalm.enabled"] = false,
                    		}
                    }
          
                    local cmp_select = {behavior = cmp.SelectBehavior.Select}
          
                    -- php keys
                    vim.keymap.set("n", "<Leader>m", ':call phpactor#ContextMenu()<CR>')
                    vim.keymap.set("n", "gd", ':call phpactor#GotoDefinition()<CR>')
                    vim.keymap.set("n", "gr", ':call phpactor#FindReference()<CR>')
          
                    -- general keybinds
                    vim.keymap.set("n", "<leader><CR>", ':FloatermToggle<CR>')
                    vim.keymap.set("t", "<leader><CR>", '<C-\\><C-n>:FloatermToggle<CR>')
                    vim.keymap.set('n', '<leader>e', vim.cmd.Ex, {})
                    vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
                    vim.keymap.set('n', '<leader>fg', builtin.git_files, {})
                    vim.keymap.set('n', '<leader>gf', builtin.live_grep, {})
                    vim.keymap.set('n', '<leader>b', builtin.buffers, {})
          
                    vim.keymap.set('v', '<silent>*', ":call VisualSelection('f')<CR>")
                    vim.keymap.set('v', '<silent>#', ":call VisualSelection('b')<CR>")
                    -- vnoremap <silent> * :call VisualSelection('f')<CR>
                    -- vnoremap <silent> # :call VisualSelection('b')<CR>
                    -- " Treat long lines as break lines (useful when moving around in them)
                    -- map j gj
                    -- map k gk
                    vim.keymap.set('n', '<leader>tn', ':tabnew<CR>')
                    vim.keymap.set('n', '<leader>to', ':tabonly<CR>')
                    vim.keymap.set('n', '<leader>tc', ':tabclose<CR>')
          
                    -- undotree
                    vim.keymap.set('n', '<leader>u', ':UndotreeToggle<CR>:UndotreeFocus<CR>')
          
          					vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv")
          					vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv")
          					vim.keymap.set('v', 'H', "<gv")
          					vim.keymap.set('v', 'L', ">gv")
                    -- vnoremap J :m '>+1<CR>gv=gv
                    -- vnoremap K :m '<-2<CR>gv=gv
                    -- vnoremap H <gv
                    -- vnoremap L >gv

                    vim.keymap.set('n', '<leader>gd', ':Gdiffsplit<CR>')
                    vim.keymap.set('n', '<leader>gb', ':Git blame<CR>')
                    vim.keymap.set('n', '<leader>gl', ':Git log<CR>')
                    vim.keymap.set('n', '<leader>gc', ':Git commit<CR>')
                    vim.keymap.set('n', '<leader>gp', ':Git push<CR>')
                    vim.keymap.set('n', '<leader>1', ':resize 10<CR>')
                    vim.keymap.set('n', '<leader>2', ':resize 20<CR>')
                    vim.keymap.set('n', '<leader>3', ':resize 30<CR>')
                    vim.keymap.set('n', '<leader>4', ':resize 40<CR>')
                    vim.keymap.set('n', '<leader>5', ':resize 50<CR>')
                    vim.keymap.set('n', '<leader>6', ':vertical resize 20<CR>')
                    vim.keymap.set('n', '<leader>7', ':vertical resize 40<CR>')
                    vim.keymap.set('n', '<leader>8', ':vertical resize 60<CR>')
                    vim.keymap.set('n', '<leader>9', ':vertical resize 80<CR>')
                    vim.keymap.set('n', '<leader>0', ':vertical resize 100<CR>')
                    vim.keymap.set('n', '<leader>db', ':DBUIToggle<CR>')
                    vim.keymap.set('n', '<leader>gs', ':Git<CR>')
        '';
      in
      {
        packages.myPlugins = with archpkgs.vimPlugins; {
          start = [
            dracula-nvim
          ];
          opt = plugins;
        };
        customRC = ''

          autocmd FileType nix set tabstop=2
          autocmd FileType nix set softtabstop=2
          autocmd FileType nix set shiftwidth=2
          autocmd FileType yaml set tabstop=2
          autocmd FileType yaml set softtabstop=2
          autocmd FileType yaml set shiftwidth=2

          luafile ${luaconfig}
        '';
      };
  };
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
      HISTSIZE=100000
      
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
      
      function ipl (){
      		${archpkgs.curl}/bin/curl -s http://ip-api.com/json/$1 | ${archpkgs.jq}/bin/jq .as
      }
      
      function iplookup (){
      		${archpkgs.curl}/bin/curl http://ip-api.com/$1
      }
      
      function motd (){
      	#6 - matrix; 25 - zelt
      	mensen=( 6 35 )
      	for mensa in "''${mensen[@]}"; do
      					${archpkgs.curl}/bin/curl -s https://api.studentenwerk-dresden.de/openmensa/v2/canteens/$mensa | ${archpkgs.jq}/bin/jq -r .name
      					while read meal; do
      									echo "$(echo "$meal" | awk -F '$' '{print $2}')€ $(echo "$meal" | awk -F '$' '{print $1}')"
      					done < <(${archpkgs.curl}/bin/curl -s https://api.studentenwerk-dresden.de/openmensa/v2/canteens/$mensa/days/$(date "+%Y-%m-%d")/meals | ${archpkgs.jq}/bin/jq -r '.[] | "\(.name)$\(.prices.Studierende)$\(.notes)"' | grep -E "vegan|vegetarisch" | grep -v suppe)
      	done
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
