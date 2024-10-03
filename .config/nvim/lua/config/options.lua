-- 編集中のファイルパスを右上に表示
-- vim.opt.winbar = "%=%m %f"
-- vim標準スペルチェックから日本語を除外
vim.opt.spelllang:append("cjk")

-- ターミナルでもTrue Colorを有効にする
vim.opt.termguicolors = true
-- floating windowの背景を透過
vim.opt.winblend = 20
-- 補完メニューの背景を透過
vim.opt.pumblend = 50

-- アクティブウィンドウの枠線の色を設定
vim.cmd([[
  hi ActiveWindowSeparator guifg=#69F5CD
  hi InactiveWindowSeparator guifg=#555555
]])

-- アクティブウィンドウの枠線を変える
vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, {
  callback = function()
    vim.wo.winhighlight = "WinSeparator:ActiveWindowSeparator"
  end,
})

-- 非アクティブウィンドウの枠線を変える
vim.api.nvim_create_autocmd("WinLeave", {
  callback = function()
    -- NeoTreeの場合は変更しない
    local filetype = vim.bo.filetype
    if filetype ~= "neo-tree" then
      vim.wo.winhighlight = ""
    end
  end,
})
