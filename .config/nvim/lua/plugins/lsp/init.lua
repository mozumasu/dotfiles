return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        virtual_text = {
          format = function(diagnostic)
            -- Add lsp server name to message
            return string.format("%s (%s)", diagnostic.message, diagnostic.source or "Unknown")
          end,
        },
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
