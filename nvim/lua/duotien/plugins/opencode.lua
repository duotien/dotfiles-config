return {
  "nickjvandyke/opencode.nvim",
  version = "*",
  dependencies = {
    {
      "folke/snacks.nvim",
      optional = true,
      opts = {
        input = {},
        picker = {
          actions = {
            opencode_send = function(...) return require("opencode").snacks_picker_send(...) end,
          },
          win = {
            input = {
              keys = {
                ["<a-a>"] = { "opencode_send", mode = { "n", "i" } },
              },
            },
          },
        },
      },
    },
  },
  config = function()
    vim.g.opencode_opts = {
      server = {
        start = function()
          require("snacks.terminal").open("opencode --port", {
            win = {
              position = "right",
              enter = false,
              on_win = function(win)
                require("opencode.terminal").setup(win.win)
              end,
            },
          })
        end,
        stop = function()
          require("snacks.terminal").get("opencode --port"):close()
        end,
        toggle = function()
          require("snacks.terminal").toggle("opencode --port")
        end,
      },
    }

    vim.o.autoread = true

    vim.keymap.set({ "n", "x" }, "<leader>oa", function() require("opencode").ask("@this: ", { submit = true }) end, { desc = "Ask opencode…" })
    vim.keymap.set({ "n", "x" }, "<leader>op", function() require("opencode").prompt() end,             { desc = "Prompt opencode…" })
    vim.keymap.set({ "n", "x" }, "<leader>os", function() require("opencode").select() end,             { desc = "Select opencode…" })
    vim.keymap.set("n",          "go",  function() return require("opencode").operator("@this ") end,        { desc = "Add range to opencode", expr = true })
    vim.keymap.set("n",          "goo", function() return require("opencode").operator("@this ") .. "_" end, { desc = "Add line to opencode", expr = true })

    vim.keymap.set({ "n" }, "<leader>ot", function() require("opencode").toggle() end,                   { desc = "Toggle opencode" })
    vim.keymap.set({ "n" }, "<leader>on", function() require("opencode").command("session.new") end,      { desc = "New session" })
    vim.keymap.set({ "n" }, "<leader>ol", function() require("opencode").command("session.select") end,   { desc = "Select session" })

    vim.keymap.set("n", "+", "<C-a>", { desc = "Increment under cursor", noremap = true })
    vim.keymap.set("n", "-", "<C-x>", { desc = "Decrement under cursor", noremap = true })
  end,
}
