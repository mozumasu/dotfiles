-- rumdl: Markdown LSP (診断 + フォーマット)
-- nix で導入済みの rumdl をそのまま使う (mason 管理外)。
-- capabilities: documentFormatting / rangeFormatting / codeAction
return {
  "neovim/nvim-lspconfig",
  opts = function(_, opts)
    vim.lsp.config("rumdl", {
      cmd = { "rumdl", "server" },
      filetypes = { "markdown" },
      root_markers = { "rumdl.toml", ".rumdl.toml", ".markdownlint.yml", ".git" },
    })
    vim.lsp.enable("rumdl")
    return opts
  end,
}
