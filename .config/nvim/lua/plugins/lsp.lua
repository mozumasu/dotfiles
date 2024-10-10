return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        virtual_text = {
          source = "always", -- Always display lsp server name
          prefix = "●",
          format = function(diagnostic)
            -- Add lsp server name to message
            return string.format("%s (%s)", diagnostic.message, diagnostic.source or "Unknown")
          end,
        },
      },
    },
  },
  require("lspconfig").typos_lsp.setup({
    init_options = {
      config = "~/.config/nvim/.typos.toml",
    },
  }),
}
