vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

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

-- keymaps
local map = vim.keymap.set

--Open Netrw file explorer Netrw
map("n", "<leader>pv", vim.cmd.Ex, {desc = "Open Netrw file explorer"})
map("n", "<leader>ps", "<cmd>e $MYVIMRC<CR>", {desc = "Open NVIM config"})


-- autocmds
local group = vim.api.nvim_create_augroup("duotien", {})

-- highlight text on yank
vim.api.nvim_create_autocmd("TextYankPost", {
    group=group,
    callback=function()
        vim.highlight.on_yank({timeout=500})
    end,
})

-- self-bootstrap: lazy.nvim
-- what this does: search for lazy.nvim,
-- if not exist -> clone
-- else: add the lazypath to rtp??
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.fn.isdirectory(lazypath) then
    local out = vim.fn.system({"git", "clone", "--filter=blob:none", "--branch=stable", "https://github.com/folke/lazy.nvim.git", lazypath})
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({{out, "ErrorMsg"}}, true)
        vim.fn.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

-- spec
vim.fn.mkdir(vim.fn.stdpath("config") .. "/lua", "p")
require("lazy").setup(require("plugins"), {
    checker = {enabled=false},
})

