local M = {}

-- Safe keymap helper
function M.map(mode, lhs, rhs, desc, opts)
  opts = opts or { noremap = true, silent = false }
  if desc then
    opts.desc = desc
  end
  vim.keymap.set(mode, lhs, rhs, opts)
end

return M
