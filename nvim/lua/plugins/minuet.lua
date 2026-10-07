return {
    -- AI inline completion (ghost text) via Ollama local model
    {
        "milanglacier/minuet-ai.nvim",
        enabled = vim.g.opts.minuet,
        -- Eager (no lazy-load event): virtualtext gates on a buffer flag set by a
        -- FileType autocmd, so buffers opened before the first InsertEnter would
        -- never get ghost text if loaded lazily. Setup is light (autocmds only).
        config = function()
            require("minuet").setup({
                provider = "openai_fim_compatible",
                n_completions = 3, -- <A-n>/<A-p> cycle through 3 candidates
                context_window = 512, -- small start; expand once speed is known
                virtualtext = {
                    auto_trigger_ft = { "python", "lua" },
                    keymap = {
                        accept = "<A-A>",       -- accept suggestion
                        accept_line = "<A-a>",  -- accept full line
                        next = "<A-n>",          -- next suggestion
                        prev = "<A-p>",          -- prev suggestion
                        dismiss = "<A-e>",      -- dismiss
                    },
                },
                provider_options = {
                    openai_fim_compatible = {
                        api_key = "TERM", -- Ollama needs a non-null placeholder env var
                        name = "Ollama",
                        -- Native API (not /v1/completions): the OpenAI-compatible
                        -- endpoint ignores options.num_ctx, so the model would stay
                        -- loaded with a 32k KV cache. Native honors it.
                        end_point = "http://localhost:11434/api/generate",
                        stream = false,
                        model = "qwen2.5-coder:1.5b",
                        get_text_fn = {
                            no_stream = function(json) return json.response end,
                        },
                        template = {
                            -- Ollama only takes the FIM branch when suffix is non-empty;
                            -- at EOF the default (empty) suffix falls back to the chat
                            -- template and the model talks instead of completing.
                            suffix = function(_, context_after_cursor)
                                return context_after_cursor ~= "" and context_after_cursor or " "
                            end,
                        },
                        transform = {
                            -- Rewrite the OpenAI-style body to native Ollama format.
                            function(data)
                                local body = data.body
                                data.body = {
                                    model = body.model,
                                    prompt = body.prompt,
                                    suffix = body.suffix,
                                    stream = false,
                                    options = {
                                        num_ctx = 4096, -- keep the KV cache small
                                        num_predict = body.max_tokens,
                                        top_p = body.top_p,
                                    },
                                }
                                return data
                            end,
                        },
                        optional = {
                            max_tokens = 56,
                            top_p = 0.9,
                        },
                    },
                },
            })

            -- Ghost text: theme's comment color but italic, so it reads as
            -- "suggestion" rather than a real comment. Re-applied on every
            -- :colorscheme so it tracks tokyonight/monokai-pro.
            local function set_ghost_hl()
                vim.api.nvim_set_hl(0, "MinuetVirtualText", { link = "Comment", italic = true })
            end
            vim.api.nvim_create_autocmd("ColorScheme", { callback = set_ghost_hl })
            set_ghost_hl()

            -- Temporarily toggle ghost text for this buffer (notify shows state)
            vim.keymap.set("n", "<leader>ug", function()
                vim.cmd("Minuet virtualtext toggle")
            end, { desc = "Toggle AI ghost text" })
        end,
    }
}
