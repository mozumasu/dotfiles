-- nb 配下のノートを「保存してから閉じた」タイミングでコミット & リモート同期する
local M = {}

local enabled = false

function M.enable()
  if enabled then
    return
  end
  enabled = true

  local pattern = require("nb.core").dir() .. "/*"
  local pending = {} -- bufnr -> filepath（保存済み・未同期のバッファ）
  local group = vim.api.nvim_create_augroup("NbCommitAndSync", { clear = true })

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    pattern = pattern,
    callback = function(args)
      pending[args.buf] = vim.api.nvim_buf_get_name(args.buf)
    end,
  })

  local function flush(buf)
    local filepath = pending[buf]
    if filepath then
      pending[buf] = nil
      require("nb.core").commit_and_sync(filepath)
    end
  end

  vim.api.nvim_create_autocmd({ "BufUnload", "BufDelete" }, {
    group = group,
    pattern = pattern,
    callback = function(args)
      flush(args.buf)
    end,
  })

  -- :wq や :qa で Vim ごと終了した場合の取りこぼし防止
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      for buf in pairs(pending) do
        flush(buf)
      end
    end,
  })
end

return M
