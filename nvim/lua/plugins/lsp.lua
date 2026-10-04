return {
    -- mason v2
    {
        "mason-org/mason.nvim",
        opts = {}, -- calls require("mason").setup() for us
    },
    {
        "mason-org/mason-lspconfig.nvim",
        opts = {
            ensure_installed = { "pyright", "lua_ls" },
        },
        dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
    },
    { "neovim/nvim-lspconfig" },
}
