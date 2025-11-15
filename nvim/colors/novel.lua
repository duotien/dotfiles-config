-- File: colors/novel.lua
-- Gogh "Novel" theme converted for Neovim
local theme = {}

theme.setup = function()
    local colors = {
        color_01   = "#000000",
        color_02   = "#CC0000",
        color_03   = "#009600",
        color_04   = "#D06B00",
        color_05   = "#0000CC",
        color_06   = "#CC00CC",
        color_07   = "#0087CC",
        color_08   = "#CCCCCC",

        color_09   = "#808080",
        color_10   = "#CC0000",
        color_11   = "#009600",
        color_12   = "#D06B00",
        color_13   = "#0000CC",
        color_14   = "#CC00CC",
        color_15   = "#0087CC",
        color_16   = "#FFFFFF",

        background = "#DFDBC3",
        foreground = "#3B2322",
        cursor     = "#3B2322",
    }

    -- Reset and declare theme name
    vim.cmd("hi clear")
    vim.g.colors_name = "novel"

    local function hi(group, opts)
        vim.api.nvim_set_hl(0, group, opts)
    end

    -- Core UI
    hi("Normal", { fg = colors.foreground, bg = colors.background })
    hi("NormalFloat", { fg = colors.foreground, bg = colors.background })
    hi("Cursor", { fg = colors.background, bg = colors.cursor })
    hi("CursorLine", { bg = "#ccc9b4" })
    hi("CursorColumn", { bg = "#ccc9b4" })
    hi("LineNr", { fg = colors.color_09, bg = colors.background })
    hi("CursorLineNr", { fg = colors.color_04 })
    hi("Visual", { bg = "#b8b5a0" })
    hi("Search", { bg = colors.color_11, fg = colors.background })
    hi("IncSearch", { bg = colors.color_10, fg = colors.background })
    hi("Pmenu", { fg = colors.foreground, bg = "#c9c6b0" })
    hi("PmenuSel", { fg = colors.background, bg = colors.color_07 })

    -- Syntax
    hi("Comment", { fg = colors.color_09, italic = true })
    hi("Identifier", { fg = colors.color_07 })
    hi("Constant", { fg = colors.color_06 })
    hi("String", { fg = colors.color_03 })
    hi("Character", { fg = colors.color_03 })
    hi("Number", { fg = colors.color_04 })
    hi("Boolean", { fg = colors.color_06 })
    hi("Float", { fg = colors.color_04 })

    hi("Function", { fg = colors.color_05 })
    hi("Keyword", { fg = colors.color_02 })
    hi("Statement", { fg = colors.color_02 })
    hi("Type", { fg = colors.color_07 })
    hi("Special", { fg = colors.color_06 })

    -- Diagnostics
    hi("DiagnosticError", { fg = colors.color_02 })
    hi("DiagnosticWarn", { fg = colors.color_04 })
    hi("DiagnosticInfo", { fg = colors.color_07 })
    hi("DiagnosticHint", { fg = colors.color_03 })

    -- Diffs
    hi("DiffAdd", { bg = "#c8e6c8" })
    hi("DiffDelete", { bg = "#e6c8c8" })
    hi("DiffChange", { bg = "#e6e2c8" })
    hi("DiffText", { bg = "#d0ccaa" })
end

theme.setup()
