-- global
-- ステータスラインを一つにまとめる
vim.opt.laststatus = 3
-- 24ビットRGBカラー有効化
vim.opt.set_option("termguicolors", true)
-- ファイル末尾に移動した際に4行分の余白設定
vim.opt.set_option("scrolloff", 4)
-- 検索時に大文字小文字無視
vim.opt.set_option("ignorecase", true)
-- 検索時に大文字が含まれていたらignorecaseを無効化
vim.opt.set_option("smartcase", true)
-- 置換時に画面下部に検索結果を表示
vim.opt.set_option("inccommand", "split")
-- クリップボードの有効化
vim.opt.set_option("clipboard", "unnamedplus")
-- クリップボードの有効化
vim.opt.clipboard:append("unnamed")

-- window
-- 行番号表示
vim.opt.win_set_option(0, "number", true)
-- 相対行番号表示
-- vim.opt.win_set_option(0, 'relativenumber', true)
-- カーソル行を強調
vim.opt.win_set_option(0, "cursorline", true)
-- 標識のためのスペースを最左列に設ける
vim.opt.win_set_option(0, "signcolumn", "yes:1")
-- テキストの折り返しを無効化
vim.opt.win_set_option(0, "wrap", false)
-- 指定したカラム列を強調
-- vim.opt.win_set_option(0, 'colorcolumn', '100')

-- python3
vim.g.python3_host_prog = "/opt/homebrew/bin/python3"

-- buffer
vim.opt.create_autocmd({ "BufEnter", "BufWinEnter" }, {
  pattern = "*",
  group = vim.opt.create_augroup("buffer_set_options", {}),
  callback = function()
    -- swapfile作成を無効化
    vim.opt.buf_set_option(0, "swapfile", true)
    -- tab幅
    vim.opt.buf_set_option(0, "tabstop", 2)
    -- tabをスペースに変換
    vim.opt.buf_set_option(0, "expandtab", true)
    -- オートインデントをtabstopの値に
    vim.opt.buf_set_option(0, "shiftwidth", 0)
  end,
})
