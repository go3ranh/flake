vim.g.mapleader = " "
vim.g.maplocalleader = ","
vim.keymap.set("n", "<leader>e", vim.cmd.Ex)

--move block of highlighted text
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("v", "H", "<gv")
vim.keymap.set("v", "L", ">gv")
vim.keymap.set("v", "<leader>r", ":SnipRun<CR>")

vim.keymap.set("n", "<leader>u", ':UndotreeToggle<CR>:UndotreeFocus<CR>')
vim.keymap.set("n", "<leader>t", ':tabedit<CR>')
vim.keymap.set("n", "<leader>mas", ':Mason<CR>')

--key bindings for vim-fugitive
vim.keymap.set("n", "<leader>gd", ':Gdiffsplit<CR>')
vim.keymap.set("n", "<leader>gb", ':Git blame<CR>')
vim.keymap.set("n", "<leader>gl", ':Git log<CR>')
vim.keymap.set("n", "<leader>gc", ':Git commit<CR>')
vim.keymap.set("n", "<leader>gp", ':Git push<CR>')

--terminal
vim.keymap.set("n", "<leader><CR>", ':FloatermToggle<CR>')
vim.keymap.set("t", "<leader><CR>", '<C-\\><C-n>:FloatermToggle<CR>')
vim.keymap.set("n", "<leader>mak", ':FloatermNew --autoclose=0 gcc % -o %< && ./%< <CR>')

--reload vimrc
vim.keymap.set("n", "<leader>rl", ':so $MYVIMRC<CR>')
--show remapped keys
vim.keymap.set("n", "<leader>sm", ':nmap<CR>')
vim.keymap.set("n", "<leader>km", ':Telescope keymaps<CR>')


vim.keymap.set("n", "<leader>1", ':resize 10<CR>')
vim.keymap.set("n", "<leader>2", ':resize 20<CR>')
vim.keymap.set("n", "<leader>3", ':resize 30<CR>')
vim.keymap.set("n", "<leader>4", ':resize 40<CR>')
vim.keymap.set("n", "<leader>5", ':resize 50<CR>')
vim.keymap.set("n", "<leader>6", ':vertical resize 20<CR>')
vim.keymap.set("n", "<leader>7", ':vertical resize 40<CR>')
vim.keymap.set("n", "<leader>8", ':vertical resize 60<CR>')
vim.keymap.set("n", "<leader>9", ':vertical resize 80<CR>')
vim.keymap.set("n", "<leader>0", ':vertical resize 100<CR>')

vim.keymap.set("n", "<leader>db", ':DBUIToggle<CR>')
