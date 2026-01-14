-- version-lsp: パッケージバージョンチェックLSP
-- https://github.com/skanehira/version-lsp

-- カスタムLSPサーバーの登録（lspconfig読み込み時に実行）
local function setup_version_lsp()
  local lspconfig = require("lspconfig")
  local configs = require("lspconfig.configs")

  if not configs.version_lsp then
    configs.version_lsp = {
      default_config = {
        cmd = { "version-lsp" },
        filetypes = { "json", "toml", "gomod", "yaml" },
        root_dir = function(fname)
          return lspconfig.util.find_git_ancestor(fname)
        end,
        settings = {},
      },
    }
  end
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- カスタムLSPを登録
      setup_version_lsp()

      -- serversに追加
      opts.servers = opts.servers or {}
      opts.servers.version_lsp = {
        cmd = { "version-lsp" },
        filetypes = { "json", "toml", "gomod", "yaml" },
        root_dir = function(fname)
          return require("lspconfig").util.find_git_ancestor(fname)
        end,
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
      }
    end,
  },
}
