return {
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "master",
        event= {"BufReadPost", "BufNewFile"},
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter.configs").setup({
                ensure_installed = {"lua","python","json","bash","markdown"},
                highlight = {enable=true},
                indent={enable=true},
            })
        end,
    },
}

