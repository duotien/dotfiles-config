return {
    -- completion
    {
        "hrsh7th/nvim-cmp",
        event = "InsertEnter",
        dependencies = { "hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path" },
        config = function()
            local cmp = require("cmp")
            cmp.setup({
                mapping = cmp.mapping.preset.insert({
                    ["<C-Space>"] = cmp.mapping.complete(),    -- force the popup
                    ["<CR>"] = cmp.mapping.confirm({ select = false }),
                    ["<Tab>"] = cmp.mapping(function(fallback) -- cycle candidates
                        if cmp.visible() then cmp.select_next_item() else fallback() end
                    end, { "i", "s" }),
                    ["<S-Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then cmp.select_prev_item() else fallback() end
                    end, { "i", "s" }),
                }),
                sources = {
                    { name = "nvim_lsp" }, -- pyright/lua_ls completions
                    { name = "buffer" },   -- words from the open file
                    { name = "path" },     -- file paths after "/"
                },
            })
        end,
    }
}
