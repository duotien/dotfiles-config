-- References:
-- ./lsp.lua                <--- you are here
-- ./core/remap.lua
-- ./plugins/nvim-cmp.lua
-- ./plugins/telescope.lua

local M = {}
function M.setup()
    vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
        callback = function(ev)
            -- local function to map the keymap
            local opts = { buffer = ev.buf, silent = false }
            local function map(mode, lhs, rhs, desc)
                local _map = require("duotien.core.utils").map
                _map(mode, lhs, rhs, desc, opts)
            end

            -- Telescope-based LSP navigation
            -- see: ./plugins/telescope.lua
            map("n", "gR", "<cmd>Telescope lsp_references<CR>", "Find References")
            map("n", "gi", "<cmd>Telescope lsp_implementations<CR>", "Go to Implementation")
            map("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", "Type Definition")
            map("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", "Show Buffer Diagnostics")

            -- LSP core functions
            map("n", "gd", vim.lsp.buf.definition, "Go to Definition")
            map("n", "K", vim.lsp.buf.hover, "Show Documentation")
            map({ "n", "i" }, "<C-h>", vim.lsp.buf.signature_help, "Show signature help")

            map("n", "<leader>vrn", vim.lsp.buf.rename, "Rename Symbol")
            map("n", "<leader>vrr", vim.lsp.buf.references, "Go to References")
            map("n", "<leader>vf", vim.lsp.buf.format, "Format")
            map({ "n", "v" }, "<leader>vca", vim.lsp.buf.code_action, "Code Action")
            map("n", "<leader>vw", vim.lsp.buf.workspace_symbol, "See Workspace symbols")

            -- Diagnostics
            map("n", "<leader>vd", vim.diagnostic.open_float, "Show Line Diagnostics")
            map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, "Prev Diagnostic")
            map("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, "Next Diagnostic")

            -- Misc
            map("n", "<leader>pr", "<cmd>LspRestart<CR>", "Restart LSP")
        end,
    })
end

return M
