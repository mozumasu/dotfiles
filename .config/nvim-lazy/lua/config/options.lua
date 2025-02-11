-- 編集中のファイルパスを右上に表示
-- vim.opt.winbar = "%=%m %f"
-- vim標準スペルチェックから日本語を除外
vim.opt.spelllang:append("cjk")
-- ヘルプの言語を日本語に設定
vim.opt.helplang = "ja"
-- ターミナルでもTrue Colorを有効にする
vim.opt.termguicolors = true

-- 初期状態で floating window の透過を有効にする
vim.opt.winblend = 20
-- コマンドラインモードに入ったときに透過を無効にする
vim.api.nvim_create_autocmd("CmdlineEnter", {
  callback = function()
    vim.opt.winblend = 0 -- 透過効果を無効にする
  end,
})
-- コマンドラインモードを終了したときに透過を再び有効にする
vim.api.nvim_create_autocmd("CmdlineLeave", {
  callback = function()
    vim.opt.winblend = 20 -- 透過効果を再び有効にする
  end,
})

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
