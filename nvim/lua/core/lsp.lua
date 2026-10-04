-- LSP keymaps: bound buffer-locally when a client attaches
vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("lsp", {}),
    callback = function(args)
        local buf = args.buf
        local map = function(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = buf, desc = desc })
        end

        map("K", vim.lsp.buf.hover, "Hover docs")
        map("<leader>vca", vim.lsp.buf.code_action, "Code action")
        map("<leader>vrn", vim.lsp.buf.rename, "Rename symbol")
        map("<leader>vf", function() vim.lsp.buf.format({ async = true }) end, "Format buffer")
        map("<leader>vd", vim.diagnostic.open_float, "Line diagnostics")
        map("[d", vim.diagnostic.goto_prev, "Prev diagnostic")
        map("]d", vim.diagnostic.goto_next, "Next diagnostic")
        -- 0.11 has no vim.lsp.buf.restart; stop the client and re-attach via re-edit
        map("<leader>pr", function()
            local _buf = vim.api.nvim_get_current_buf()
            for _, client in ipairs(vim.lsp.get_active_clients({ bufnr = _buf })) do
                client:stop(true)
            end
            vim.cmd.edit()
        end, "Restart LSP")

        -- signature help in insert mode
        vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, { buffer = buf, desc = "Signature help" })
    end,
})
