return {
    "nickjvandyke/opencode.nvim",
    enabled = vim.g.opts.opencode,
    -- main branch = OpenCode v2 (what we run)
    config = function(opts)
        vim.g.opencode_opts = opts
    end,
    opts = {},              -- defaults: auto-detect a running `opencode` daemon; start one if none
    keys = { "<leader>o" }, -- lazy-load on the o prefix
}
