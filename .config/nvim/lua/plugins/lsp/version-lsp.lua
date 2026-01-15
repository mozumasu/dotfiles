-- version-lsp: パッケージバージョンチェックLSP
-- https://github.com/skanehira/version-lsp

return {
  {
    "neovim/nvim-lspconfig",
    opts = function()
      -- autocmdでversion-lspを起動
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "json", "toml", "gomod", "yaml" },
        callback = function(args)
          local root_dir = vim.fs.root(args.buf, { ".git" })
          if not root_dir then
            return
          end

          vim.lsp.start({
            name = "version_lsp",
            cmd = { "version-lsp" },
            root_dir = root_dir,
            settings = {
              ["version-lsp"] = {
                cache = { refreshInterval = 86400000 }, -- 24時間
                registries = {
                  npm = { enabled = true },
                  crates = { enabled = true },
                  goProxy = { enabled = true },
                  github = { enabled = true },
                },
              },
            },
          })
        end,
      })
    end,
  },
}
