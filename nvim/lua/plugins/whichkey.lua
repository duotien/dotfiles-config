return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
        spec = {
            { "<leader>f", group = "finder" },
            { "<leader>g", group = "git" },
            { "<leader>v", group = "views" },
            { "<leader>p", group = "project" },
            { "<leader>u", group = "ui" },
        },
    },
}
