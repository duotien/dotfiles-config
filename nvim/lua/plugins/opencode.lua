return {
    "duotien/opencode.nvim", -- our fork; upstream sync via dev clone (~/Workspaces/GIT/opencode.nvim)
    enabled = vim.g.opts.opencode,
    branch = "staging",      -- track the fork's staging branch
    config = function(opts)
        vim.g.opencode_opts = opts
    end,
    opts = {},              -- defaults: auto-detect a running `opencode` daemon; start one if none
    keys = { "<leader>o" }, -- lazy-load on the o prefix
}
