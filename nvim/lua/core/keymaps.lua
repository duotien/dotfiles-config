local map = vim.keymap.set

--Open Netrw file explorer Netrw
map("n", "<leader>pv", vim.cmd.Ex, { desc = "Open Netrw file explorer" })
map("n", "<leader>ps", "<cmd>e $MYVIMRC<CR>", { desc = "Open NVIM config" })

-- snack-picker
map("n", "<leader>ff", function() require("snacks.picker").files() end, { desc = "Find files" })
map("n", "<leader>fg", function() require("snacks.picker").grep({ focus = "input" }) end, { desc = "Live grep" })
map("n", "<leader>fb", function() require("snacks.picker").buffers() end, { desc = "Find buffers" })
map("n", "<leader>z", function() require("snacks").zen() end, { desc = "Zen mode" })

-- snack-picker: git
map("n", "<leader>gl", function() require("snacks.picker").git_log() end, { desc = "Git log" })
map("n", "<leader>gs", function() require("snacks.picker").git_status() end, { desc = "Git status" })

-- snack-picker: colorschemes
map("n", "<leader>uc", function() require("snacks.picker").colorschemes() end, { desc = "Colorscheme" })
