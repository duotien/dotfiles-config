vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- core
require("core.options")
require("core.keymaps")
require("core.autocmds")
require("core.lsp")

-- lazy.nvim bootstrap
-- what this does: search for lazy.nvim,
-- if not exist -> clone
-- else: add the lazypath to rtp
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.fn.isdirectory(lazypath) then
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable",
        "https://github.com/folke/lazy.nvim.git", lazypath })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({ { out, "ErrorMsg" } }, true)
        vim.fn.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

-- spec
vim.fn.mkdir(vim.fn.stdpath("config") .. "/lua", "p")
require("lazy").setup(require("plugins"), {
    checker = { enabled = false },
})
