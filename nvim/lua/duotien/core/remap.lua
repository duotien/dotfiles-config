-- References:
-- ../lsp.lua
-- ./remap.lua              <--- you are here
-- ../plugins/nvim-cmp.lua
-- ../plugins/telescope.lua

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- local function to map the keymap
local map = require("duotien.core.utils").map

map("n", "<leader>pv", vim.cmd.Ex, "Open Netrw")

-- for lsp config, go to ../lsp.lua (gf)
