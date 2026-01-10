-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- クリップボード連携を無効化（TextYankPostでヤンク時のみ連携する）
-- LazyVimのデフォルト: vim.opt.clipboard = "unnamedplus"
vim.opt.clipboard = ""

-- 編集中のファイルパスを右上に表示
-- vim.opt.winbar = "%=%m %f"
-- vim標準スペルチェックから日本語を除外
vim.opt.spelllang:append("cjk")
-- スペル辞書の設定（dotfiles管理 + ローカル専用）
-- zg: dotfiles管理の辞書、2zg: ローカル専用の辞書
vim.opt.spellfile = {
  vim.fn.stdpath("config") .. "/spell/en.utf-8.add",
  vim.fn.stdpath("data") .. "/spell/local.utf-8.add",
}

-- Enable this option to avoid conflicts with Prettier.
vim.g.lazyvim_prettier_needs_config = true

--
-- Window
--
-- open window at right side when vertical split
vim.opt.splitright = true
-- open window at bottom side when horizontal split
vim.opt.splitbelow = true

--
-- Help
--
vim.opt.helplang = "ja"
-- Create a command-line abbreviation for 'H' to open help in a vertical split on the right
vim.cmd("cabbrev H belowright vertical help")

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

-- 補完メニューの背景透過（低めに設定して視認性を確保）
vim.opt.pumblend = 10

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
vim.opt.whichwrap = "b,s,h,l,<,>,[,],~"

-- Terminal colors (WezTerm "Solarized Dark Higher Contrast" scheme)
-- WezTerm の :terminal でカラーパレットを一致させる
-- ANSI colors (0-7)
vim.g.terminal_color_0 = "#002831" -- black
vim.g.terminal_color_1 = "#d11c24" -- red
vim.g.terminal_color_2 = "#6cbe6c" -- green
vim.g.terminal_color_3 = "#a57706" -- yellow
vim.g.terminal_color_4 = "#2176c7" -- blue
vim.g.terminal_color_5 = "#c61c6f" -- magenta
vim.g.terminal_color_6 = "#259286" -- cyan
vim.g.terminal_color_7 = "#eae3cb" -- white
-- Bright colors (8-15)
vim.g.terminal_color_8 = "#006488" -- bright black
vim.g.terminal_color_9 = "#f5163b" -- bright red
vim.g.terminal_color_10 = "#51ef84" -- bright green
vim.g.terminal_color_11 = "#b27e28" -- bright yellow
vim.g.terminal_color_12 = "#178ec8" -- bright blue
vim.g.terminal_color_13 = "#e24d8e" -- bright magenta
vim.g.terminal_color_14 = "#00b39e" -- bright cyan
vim.g.terminal_color_15 = "#fcf4dc" -- bright white

-- LSP hover/signature help のボーダー設定
vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
  border = "rounded",
})
vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
  border = "rounded",
})
