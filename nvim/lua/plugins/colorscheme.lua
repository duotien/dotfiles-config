return {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function(opts)
        require("tokyonight").setup(opts)
        vim.cmd.colorscheme("tokyonight-night")
    end,
    opts = {
        style = "storm", -- dark; other variants: moon, night
    },
}
