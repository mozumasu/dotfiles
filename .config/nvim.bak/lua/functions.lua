local nvim_create_user_command = vim.api.nvim_create_user_command

-- nvim上でmdのプレビューを表示
nvim_create_user_command("Glow", function()
  if not vim.fn.executable("glow") then
    vim.notify("Not found glow command.", vim.log.levels.ERROR)
    return
  end

  -- markdownファイル以外で実行した場合はエラーを出力
  if not string.match(vim.fn.expand("%:p"), "%.md$") then
    vim.notify("This is not a markdown file.", vim.log.levels.ERROR)
    return
  end

  vim.cmd([[
    execute('vs | wincmd j | resize 100 | terminal glow')
    " TermClose の時点で現在フォーカスされている無関係なバッファに bdelete を送信することを回避し、
    " 代わりに TermClose をトリガーした実際のバッファをターゲットすることでエラーを回避する
    " https://github.com/neovim/neovim/issues/14986#issuecomment-902705190
    autocmd TermClose * execute 'bdelete! ' . expand('<abuf>')
  ]])
end, {})
