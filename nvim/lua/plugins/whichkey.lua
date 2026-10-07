return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = function()
        local spec = {
            { "<leader>f", group = "finder" },
            { "<leader>g", group = "git" },
            { "<leader>v", group = "views" },
            { "<leader>p", group = "project" },
            { "<leader>u", group = "ui" },
        }
        if vim.g.opts.opencode then
            table.insert(spec, { "<leader>o", group = "opencode" })
        end
        return { spec = spec }
    end,
}
