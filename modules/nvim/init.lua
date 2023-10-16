require("goeranh.remap")
require("goeranh.set")
require("goeranh.packer")

require('orgmode').setup_ts_grammar()
require('orgmode').setup({
  org_agenda_files = {'~/Documents/org/*'},
  org_default_notes_file = '~/Documents/org/refile.org',
  org_capture_templates = {
	  r = {
	    description = "Repo",
	    template = "* [[%x][%(return string.match('%x', '([^/]+)$'))]]%?",
	    target = "~/Documents/org/repos.org",
	  },
	  n = {
	    description = "Notes",
	    template = "*",
	    target = "~/Documents/org/notes.org",
	  }
  }
})
vim.cmd[[colorscheme dracula]]
--vim.cmd[[colorscheme PaperColor]]
--vim.cmd[[set background=dark]]
vim.cmd[[let g:netrw_bufsettings = 'noma nomod nu nowrap ro nobl']]
