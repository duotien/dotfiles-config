vim.lsp.config('pyright', {
    settings = {
        pyright = {
            -- Using Ruff's import organizer
            disableOrganizeImports = true,
        },
        python = {
            -- Point Pyright at the project's venv. Recent Pyright versions no
            -- longer auto-detect .venv, so it must be specified explicitly.
            venvPath = ".",
            venv = ".venv",
            analysis = {
                -- Ignore all files for analysis to exclusively use Ruff for linting
                -- ignore = { '*' },
                typeCheckingMode = "standard",

                -- for `uv`
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                autoImportCompletions = true,
            },
        },
    },
})
