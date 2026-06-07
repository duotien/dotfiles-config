return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    bigfile = { enabled = true },
    indent = { enabled = true },
    input = { enabled = true },
    notifier = {
      enabled = true,
      timeout = 3000,
    },
    scope = { enabled = true },
    scroll = { enabled = true },
    statuscolumn = { enabled = true },
    styles = {
      notification = {
        wo = { wrap = true },
      },
    },
  },
  keys = {
    -- LSP
    { "gd", function() require("snacks").picker.lsp_definitions() end, desc = "Goto Definition" },
    { "gD", function() require("snacks").picker.lsp_declarations() end, desc = "Goto Declaration" },
    { "gr", function() require("snacks").picker.lsp_references() end, nowait = true, desc = "References" },
    { "gI", function() require("snacks").picker.lsp_implementations() end, desc = "Goto Implementation" },
    { "gy", function() require("snacks").picker.lsp_type_definitions() end, desc = "Goto T[y]pe Definition" },
    { "<leader>ss", function() require("snacks").picker.lsp_symbols() end, desc = "LSP Symbols" },
    { "<leader>sS", function() require("snacks").picker.lsp_workspace_symbols() end, desc = "LSP Workspace Symbols" },
    -- Other
    { "<leader>z", function() require("snacks").zen() end, desc = "Toggle Zen Mode" },
    { "<leader>Z", function() require("snacks").zen.zoom() end, desc = "Toggle Zoom" },
    { "<leader>bd", function() require("snacks").bufdelete() end, desc = "Delete Buffer" },
    { "<leader>pt", function() require("snacks").terminal() end, desc = "Toggle Terminal" },
    { "<c-_>", function() require("snacks").terminal() end, desc = "which_key_ignore" },
    { "]]", function() require("snacks").words.jump(vim.v.count1) end, desc = "Next Reference", mode = { "n", "t" } },
    { "[[", function() require("snacks").words.jump(-vim.v.count1) end, desc = "Prev Reference", mode = { "n", "t" } },
  },
  init = function()
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      callback = function()
        -- Setup some globals for debugging (lazy-loaded)
        _G.dd = function(...)
          require("snacks").debug.inspect(...)
        end
        _G.bt = function()
          require("snacks").debug.backtrace()
        end

        -- Create some toggle mappings
        require("snacks").toggle.option("spell", { name = "Spelling" }):map("<leader>us")
        require("snacks").toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
        require("snacks").toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
        require("snacks").toggle.diagnostics():map("<leader>ud")
        require("snacks").toggle.line_number():map("<leader>ul")
        require("snacks").toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map("<leader>uc")
        require("snacks").toggle.treesitter():map("<leader>uT")
        require("snacks").toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
        require("snacks").toggle.inlay_hints():map("<leader>uh")
        require("snacks").toggle.indent():map("<leader>ug")
        require("snacks").toggle.dim():map("<leader>uD")
      end,
    })
  end,
}
