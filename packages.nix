{ inputs, lib, self, archpkgs, ... }@input: rec {
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

          vim-tmux-navigator

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
          git-worktree-nvim

          orgmode

          vim-floaterm
          nvim-tree-lua
          undotree
        ] ++ [ self.packages.${archpkgs.stdenv.hostPlatform.system}.gitsigns ];

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
          
                    require'gitsigns'.setup{
                      on_attach = function(bufnr)
          							local gitsigns = require('gitsigns')
          						 	local function map(mode, l, r, opts)
          						 		opts = opts or {}
          						 		opts.buffer = bufnr
          						 		vim.keymap.set(mode, l, r, opts)
          						 	end
          						
          							-- Navigation
          							map('n', '+c', function()
          								if vim.wo.diff then
          									vim.cmd.normal({']c', bang = true})
          								else
          									gitsigns.nav_hunk('next')
          								end
          							end)
          							
          							map('n', 'üc', function()
          								if vim.wo.diff then
          									vim.cmd.normal({'[c', bang = true})
          								else
          									gitsigns.nav_hunk('prev')
          								end
          							end)
          						-- 	
          						-- 	-- Actions
          						-- 	--map('n', '<leader>hs', gitsigns.stage_hunk)
          						-- 	--map('n', '<leader>hr', gitsigns.reset_hunk)
          						-- 	--map('v', '<leader>hs', function() gitsigns.stage_hunk {vim.fn.line('.'), vim.fn.line('v')} end)
          						-- 	--map('v', '<leader>hr', function() gitsigns.reset_hunk {vim.fn.line('.'), vim.fn.line('v')} end)
          						-- 	--map('n', '<leader>hS', gitsigns.stage_buffer)
          						-- 	--map('n', '<leader>hu', gitsigns.undo_stage_hunk)
          						-- 	--map('n', '<leader>hR', gitsigns.reset_buffer)
          						-- 	--map('n', '<leader>hp', gitsigns.preview_hunk)
          						-- 	--map('n', '<leader>hb', function() gitsigns.blame_line{full=true} end)
          						-- 	--map('n', '<leader>tb', gitsigns.toggle_current_line_blame)
          						-- 	--map('n', '<leader>hd', gitsigns.diffthis)
          						-- 	--map('n', '<leader>hD', function() gitsigns.diffthis('~') end)
          						-- 	--map('n', '<leader>td', gitsigns.toggle_deleted)
          						-- 	
          						-- 	---- Text object
          						-- 	--map({'o', 'x'}, 'ih', ':<C-U>Gitsigns select_hunk<CR>')
                      end
          					}
                    -- require'gitsigns'.setup{
                    --   signs = {
          					-- 		add          = { text = '┃' },
          					-- 		change       = { text = '┃' },
          					-- 		delete       = { text = '_' },
          					-- 		topdelete    = { text = '‾' },
          					-- 		changedelete = { text = '~' },
          					-- 		untracked    = { text = '┆' },
                    --   },
                    --   signcolumn = true,  -- Toggle with `:Gitsigns toggle_signs`
                    --   numhl      = true, -- Toggle with `:Gitsigns toggle_numhl`
                    --   linehl     = false, -- Toggle with `:Gitsigns toggle_linehl`
                    --   word_diff  = true, -- Toggle with `:Gitsigns toggle_word_diff`
                    --   watch_gitdir = {
          					-- 		follow_files = true
                    --   },
                    --   --auto_attach = true,
                    --   attach_to_untracked = false,
                    --   current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
                    --   current_line_blame_opts = {
          					-- 		virt_text = true,
          					-- 		virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
          					-- 		delay = 1000,
          					-- 		ignore_whitespace = false,
          					-- 		virt_text_priority = 100,
                    --   },
                    --   current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d> - <summary>',
                    --   current_line_blame_formatter_opts = {
          					-- 		relative_time = false,
                    --   },
                    --   sign_priority = 6,
                    --   update_debounce = 100,
                    --   status_formatter = nil, -- Use default
                    --   max_file_length = 40000, -- Disable if file is longer than this (in lines)
                    --   preview_config = {
          					-- 		-- Options passed to nvim_open_win
          					-- 		border = 'single',
          					-- 		style = 'minimal',
          					-- 		relative = 'cursor',
          					-- 		row = 0,
          					-- 		col = 1
                    --   },
                    --   --map('n', '<leader>hd', gitsigns.diffthis)
                    -- }
          
                    require'lspconfig'.phpactor.setup{
          						on_attach = on_attach,
          						init_options = {
          							["language_server_phpstan.enabled"] = false,
          							["language_server_psalm.enabled"] = false,
          						}
                    }
          
                    local cmp_select = {behavior = cmp.SelectBehavior.Select}
          
                    require("telescope").load_extension("git_worktree")
                    vim.keymap.set('n', '<leader>gwn', ':lua require(\'telescope\').extensions.git_worktree.create_git_worktree()<cr>')
                    vim.keymap.set('n', '<leader>gws', ':lua require(\'telescope\').extensions.git_worktree.git_worktrees()<cr>')
          
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
                    vim.keymap.set('n', '<leader>gsb', ':Gitsigns toggle_current_line_blame<CR>')
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
          #start = [
          #  dracula-nvim
          #];
          opt = plugins;
        };
        customRC = ''
          				  let g:tmux_navigator_no_mappings = 1
          					noremap <silent> <M-h> :<C-U>TmuxNavigateLeft<cr>
                    noremap <silent> <M-j> :<C-U>TmuxNavigateDown<cr>
                    noremap <silent> <M-k> :<C-U>TmuxNavigateUp<cr>
                    noremap <silent> <M-l> :<C-U>TmuxNavigateRight<cr>
                    noremap <silent> <M-#> :<C-U>TmuxNavigatePrevious<cr>

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
  gitsigns = archpkgs.neovimUtils.buildNeovimPlugin {
    pname = "gitsigns.nvim";
    version = "v0.7";
    src = archpkgs.fetchFromGitHub {
      owner = "lewis6991";
      repo = "gitsigns.nvim";
      rev = "6ef8c54fb526bf3a0bc4efb0b2fe8e6d9a7daed2";
      sha256 = "sha256-cVs6thVq70ggQTvK/wEi377OgXqoaX3ulnyr+z6s0iA=";
    };
    meta.homepage = "https://github.com/tpope/vim-fugitive/";
  };
  settings = archpkgs.stdenv.mkDerivation rec {
    buildInputs = with archpkgs; [ fzf bfs git ];
    name = "settings";
    description = "goeranh settings / dotfiles";
    bashrc = archpkgs.writeText ".bashrc" ''
            			FZF_ALT_C_COMMAND= eval "$(${archpkgs.fzf.outPath}/bin/fzf --bash)"
      						eval "$(${archpkgs.zoxide.outPath}/bin/zoxide init bash)"
      						. ${archpkgs.git.outPath}/share/bash-completion/completions/git
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
      export EDITOR="nvim"
      
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
  updateAll = archpkgs.writeShellScriptBin "updateAll" ''
        echo "update all"
    		for host in $(echo "${builtins.concatStringsSep " " (builtins.attrNames self.nixosConfigurations)}"); do
    			echo $host
    			${archpkgs.nixos-rebuild.outPath}/bin/nixos-rebuild switch --flake .#$host --target-host $host --build-host $host --use-remote-sudo
    		done
    	'';
}
