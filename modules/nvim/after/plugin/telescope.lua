local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.git_files, {})
vim.keymap.set('n', '<leader>gf', builtin.live_grep, {})
vim.keymap.set('n', '<leader>b', builtin.buffers, {})
require'nvim-treesitter.configs'.setup {
  indent = {
    enable = true
  }
}
