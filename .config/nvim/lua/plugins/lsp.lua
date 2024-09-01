return {
  require("lspconfig").typos_lsp.setup({
    init_options = {
      config = "~/.config/nvim/.typos.toml",
    },
  }),
}
