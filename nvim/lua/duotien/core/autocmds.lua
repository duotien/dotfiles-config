local group = vim.api.nvim_create_augroup("MyAutoCmds", {})

-- Hight-light text on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  callback = function()
    vim.highlight.on_yank({ timeout = 500 })
  end,
})
