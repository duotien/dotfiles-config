vim.opt.clipboard = 'unnamedplus' -- use system clipboard

vim.opt.nu = true                 -- set line numbers
vim.opt.relativenumber = true     -- use relative line numbers

-- set tab size to 4 spaces
vim.opt.expandtab = true     -- Use spaces instead of tabs
vim.opt.shiftwidth = 4       -- Indent size
vim.opt.tabstop = 4          -- Tab width
vim.opt.smartindent = true   -- Smarter autoindent

vim.opt.incsearch = true     -- incremental search
vim.opt.ignorecase = true    -- Case-insensitive searching...
vim.opt.smartcase = true     -- ...unless capital letters are used

vim.opt.wrap = false         -- No line wrapping
vim.opt.scrolloff = 8        -- Keep cursor away from screen edge
vim.opt.signcolumn = "yes"   -- Always show sign column
-- vim.opt.updatetime = 250           -- Faster updates (good for LSP)
vim.opt.termguicolors = true -- True color support


-- set leader key before lazy

vim.cmd("colorscheme novel")

require("duotien.core.remap")
require("duotien.core.autocmds")

