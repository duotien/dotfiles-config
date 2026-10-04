---@type vim.lsp.Config
return {
    settings = {
        pyright = {
            -- ruff handles import organization
            disableOrganizeImports = true,
        },
    },
}
