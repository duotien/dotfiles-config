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
map("n", "<leader>ps", "<cmd>e $MYVIMRC<CR>", "Open $MYVIMRC")

-- Write buffer and return to the Netrw file explorer (never exit nvim).
-- Neovim built-ins take precedence over same-name user commands, so ":wq"
-- cannot be overridden; use <leader>q instead.
local function save_and_netrw()
  if vim.bo.modified then
    vim.cmd("write")
  end
  local found = false
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "netrw" then
      vim.api.nvim_set_current_win(win)
      found = true
      break
    end
  end
  if not found then
    vim.cmd("Ex")
  end
end

map("n", "<leader>q", save_and_netrw, "Write and return to Netrw")

-- for lsp config, go to ../lsp.lua (gf)
