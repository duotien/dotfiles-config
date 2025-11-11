return {
  'nvim-telescope/telescope.nvim',
  tag = '0.1.8',
  dependencies = { 'nvim-lua/plenary.nvim' },

  config = function()
    local telescope = require("telescope")

    telescope.setup({
      defaults = {
        -- prompt_prefix = "  ",
        -- selection_caret = " ",
        -- path_display = { "smart" },
        -- layout_config = { prompt_position = "top" },
        -- sorting_strategy = "ascending",
      },
    })

    -- Optional keymaps for common actions
    local telescope_builtin = require("telescope.builtin")
    local map = require("duotien.core.utils").map
    map('n', '<leader>ff', telescope_builtin.find_files, 'Telescope find files')
    map('n', '<leader>fg', telescope_builtin.live_grep, 'Telescope live grep')
    map('n', '<leader>fb', telescope_builtin.buffers, 'Telescope buffers')
    map('n', '<leader>fh', telescope_builtin.help_tags, 'Telescope help tags')

    -- Telescope-based LSP navigation
    -- see: ../lsp.lua
  end,
}
