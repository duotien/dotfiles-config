return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
    icons = { mappings = false, },
    plugins = { marks = true, registers = true, },
    windows = { border = "rounded", },
    layout = { spacing = 6, }
  },
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer Local Keymaps (which-key)",
    },
  },
  config = function(_, opts)
    local wk = require("which-key")
    wk.setup(opts)

    -- Example keymap registration
    wk.add({
      { "<leader>f",  group = "file" }, -- group name for file operations
      { "<leader>v",  group = "code" },
      { "<leader>vc", group = "code" },
      { "<leader>p",  group = "project" },
    })
  end,
}
