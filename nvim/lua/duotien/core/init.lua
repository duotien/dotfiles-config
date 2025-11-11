vim.opt.clipboard = 'unnamedplus' -- use system keyboard for yank, which also copy to the system clipboard.

vim.opt.nu = true                 -- set line numbers
vim.opt.relativenumber = true     -- use relative line numbers

-- set tab size to 2 spaces
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true

-- vim.opt.termguicolors = false

vim.opt.wrap = false

vim.opt.incsearch = true -- incremental search

-- set leader key before lazy

require("duotien.core.remap")

