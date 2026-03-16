return {
  -- Disable markdownlint (use rumdl instead via CLI)
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        markdown = {},
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    keys = {
      {
        "<leader>cD",
        function()
          local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
          local diagnostics = vim.diagnostic.get(0, { lnum = lnum })
          if #diagnostics == 0 then return end

          local messages = {}
          for _, d in ipairs(diagnostics) do
            table.insert(messages, string.format("[%s] %s", d.source or "Unknown", d.message))
          end
          local text = table.concat(messages, "\n")

          require("plamo-translate.translate").translate(text, function(result, err)
            if err or not result then
              vim.diagnostic.open_float()
              return
            end
            require("plamo-translate.ui").show(result, { position = "cursor" })
          end)
        end,
        desc = "Line Diagnostics (Translated)",
      },
    },
    opts = {
      diagnostics = {
        virtual_text = {
          format = function(diagnostic)
            -- Add lsp server name to message
            return string.format("%s (%s)", diagnostic.message, diagnostic.source or "Unknown")
          end,
        },
        float = { border = "rounded" },
      },
    },
  },
  {
    "saghen/blink.cmp",
    opts = {
      completion = {
        menu = {
          border = "rounded",
        },
        documentation = {
          window = {
            border = "rounded",
          },
        },
      },
      keymap = {
        -- preset = "none",
        ["<CR>"] = {}, -- Do not use enter to confirm completion
      },
      sources = {
        default = {
          cmdline = {}, -- Disable cmdline completions (conflicts with Snacks picker)
        },
      },
    },
  },
}
