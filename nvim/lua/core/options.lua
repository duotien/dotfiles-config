vim.opt.clipboard = "unnamedplus" -- use system clipboard
vim.opt.number = true             -- show line numbers
vim.opt.relativenumber = true     -- current line shows 0, others relative
vim.opt.syntax = "on"             -- built-in highlighting (default_vimrc is skipped once you have init.lua)

vim.opt.expandtab = true          -- insert spaces, not tabs
vim.opt.shiftwidth = 4            -- indent width in spaces
vim.opt.tabstop = 4               -- display width of existing tab characters
vim.opt.smartindent = true        -- autoindent that tracks code structure (C-ish heuristics)

vim.opt.incsearch = true          -- show search matches while typing
vim.opt.ignorecase = true         -- search case-insensitive...
vim.opt.smartcase = true          -- ...unless the query contains capitals

vim.opt.wrap = false              -- long lines scroll, don't wrap
vim.opt.scrolloff = 8             -- keep 8 lines of context above/below cursor
vim.opt.signcolumn = "yes"        -- gutter always visible (no layout shift when signs appear)
vim.opt.termguicolors = true      -- 24-bit colors in terminal
