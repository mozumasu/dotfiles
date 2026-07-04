local M = {}

M.defaults = {
  -- nb のデータディレクトリ（nil なら $NB_DIR → ~/.nb の順で解決）
  dir = nil,
  -- `nb browse` のポート番号（別 notebook の画像リンク生成・解決に使用）
  browse_port = 6789,
  -- 保存したノートをバッファを閉じたときに自動コミット & リモート同期
  autosync = true,
  -- 新規ノートのファイル名に使うタイムスタンプ形式
  timestamp_format = "%Y%m%d%H%M%S",
  -- picker のカスタムプレビュー関数 function(ctx) （nil なら snacks のファイルプレビュー）
  preview = nil,
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
end

function M.dir()
  local dir = M.options.dir or vim.env.NB_DIR or "~/.nb"
  return (vim.fn.expand(dir):gsub("/$", ""))
end

return M
