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
    -- second scheme, switched via :colorscheme monokai-pro or <leader>uc
    {
        "loctvl842/monokai-pro.nvim",
        lazy = true,
        opts = {
            filter = "pro", -- variants: classic, octagon, machine, ristretto, spectrum, light
        },
    },
}
