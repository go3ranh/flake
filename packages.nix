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
          lsp-zero-nvim
          nvim-lspconfig
          mason-nvim
          mason-lspconfig-nvim
          nvim-cmp
          cmp-buffer
          cmp-path
          cmp-nvim-lsp
          cmp-nvim-lua
          cmp-nvim-tags
          orgmode
          sniprun
          vim-floaterm
          nvim-web-devicons
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
                            local builtin = require('telescope.builtin')
          									vim.keymap.set("n", "<leader><CR>", ':FloatermToggle<CR>')
          									vim.keymap.set("t", "<leader><CR>", '<C-\\><C-n>:FloatermToggle<CR>')
                            vim.keymap.set('n', '<leader>e', vim.cmd.Ex, {})
                            vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
                            vim.keymap.set('n', '<leader>fg', builtin.git_files, {})
                            vim.keymap.set('n', '<leader>gf', builtin.live_grep, {})
                            vim.keymap.set('n', '<leader>b', builtin.buffers, {})
                            local lsp = require('lsp-zero')

                            lsp.preset('recommended')

                            lsp.ensure_installed({
                            	'tsserver',
                            	'eslint'
                            })

                            local cmp = require('cmp')
														cmp.setup {

															mapping = {

																-- ... Your other configuration ...

																['<C-Space>'] = cmp.mapping.confirm {
																	behavior = cmp.ConfirmBehavior.Insert,
																	select = true,
																},

																['<Tab>'] = function(fallback)
																	if not cmp.select_next_item() then
																		if vim.bo.buftype ~= 'prompt' and has_words_before() then
																			cmp.complete()
																		else
																			fallback()
																		end
																	end
																end,

																['<S-Tab>'] = function(fallback)
																	if not cmp.select_prev_item() then
																		if vim.bo.buftype ~= 'prompt' and has_words_before() then
																			cmp.complete()
																		else
																			fallback()
																		end
																	end
																end,
															},

															snippet = {
																-- We recommend using *actual* snippet engine.
																-- It's a simple implementation so it might not work in some of the cases.
																expand = function(args)
																	unpack = unpack or table.unpack
																	local line_num, col = unpack(vim.api.nvim_win_get_cursor(0))
																	local line_text = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, true)[1]
																	local indent = string.match(line_text, '^%s*')
																	local replace = vim.split(args.body, '\n', true)
																	local surround = string.match(line_text, '%S.*') or "" 
																	local surround_end = surround:sub(col)

																	replace[1] = surround:sub(0, col - 1)..replace[1]
																	replace[#replace] = replace[#replace]..(#surround_end > 1 and ' ' or "")..surround_end
																	if indent ~= "" then
																		for i, line in ipairs(replace) do
																			replace[i] = indent..line
																		end
																	end

																	vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, true, replace)
																end,
															},
														}
                            local cmp_select = {behavior = cmp.SelectBehavior.Select}
                            local cmp_mappings = lsp.defaults.cmp_mappings({
                              ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
                              ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
                              ['<C-y>'] = cmp.mapping.confirm({ select = true }),
                              ["<C-Space>"] = cmp.mapping.complete(),
                            })

                            lsp.on_attach(function(client, bufnr)
                              local opts = {buffer = bufnr, remap = false}

                              if client.name == "eslint" then
                                  vim.cmd.LspStop('eslint')
                                  return
                              end

                              vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
                              vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
                              vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float, opts)
                              vim.keymap.set("n", "[d", vim.diagnostic.goto_next, opts)
                              vim.keymap.set("n", "]d", vim.diagnostic.goto_prev, opts)
                            end)


                            lsp.setup()
        '';
      in
      {
        packages.myPlugins = with archpkgs.vimPlugins; {
          start = [
            dracula-nvim
          ];
          opt = [
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
            lsp-zero-nvim
            nvim-lspconfig
            mason-nvim
            mason-lspconfig-nvim
            nvim-cmp
            cmp-buffer
            cmp-path
            cmp-nvim-lsp
            cmp-nvim-lua
            cmp-nvim-tags
            orgmode
            sniprun
            vim-floaterm
            nvim-web-devicons
            nvim-tree-lua
          ];
        };
        customRC = ''
          set nocompatible
          set backspace=indent,eol,start
          set nu rnu
          set tabstop=4
          set softtabstop=4
          set shiftwidth=4
          set smartindent
          set noswapfile
          set nobackup
          set nohlsearch
          set incsearch
          set termguicolors
          set scrolloff=8
          set undodir=$HOME/.vim/undodir
          let mapleader=" "
          colorscheme dracula

          vnoremap <silent> * :call VisualSelection('f')<CR>
          vnoremap <silent> # :call VisualSelection('b')<CR>
          " Treat long lines as break lines (useful when moving around in them)
          map j gj
          map k gk
          "Useful mappings for managing tabs
          map <leader>tn :tabnew<cr>
          map <leader>to :tabonly<cr>
          map <leader>tc :tabclose<cr>
          map <leader>tm :tabmove 

          map <leader>mas :Mason<CR>
          map <leader>u :UndotreeToggle<CR>:UndotreeFocus<CR>
          vnoremap J :m '>+1<CR>gv=gv
          vnoremap K :m '<-2<CR>gv=gv
          vnoremap H <gv
          vnoremap L >gv
          vnoremap <leader>r :SnipRun<CR>
          map <leader>gd :Gdiffsplit<CR>
          map <leader>gb :Git blame<CR>
          map <leader>gl :Git log<CR>
          map <leader>gc :Git commit<CR>
          map <leader>gp :Git push<CR>
          map <leader>1 :resize 10<CR>
          map <leader>2 :resize 20<CR>
          map <leader>3 :resize 30<CR>
          map <leader>4 :resize 40<CR>
          map <leader>5 :resize 50<CR>
          map <leader>6 :vertical resize 20<CR>
          map <leader>7 :vertical resize 40<CR>
          map <leader>8 :vertical resize 60<CR>
          map <leader>9 :vertical resize 80<CR>
          map <leader>0 :vertical resize 100<CR>
          map <leader>db :DBUIToggle<CR>
          map <leader>gs :Git<CR>

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
