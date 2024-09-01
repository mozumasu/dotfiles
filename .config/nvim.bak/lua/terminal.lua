local keyset = vim.api.nvim_set_keymap
local user_command = vim.api.nvim_create_user_command

-- Terminalのインサートモードからの離脱
vim.api.nvim_set_keymap('t', '<Esc>', '<C-\\><C-n>', {noremap = true})

-- 開き方
user_command('T', function(args)
  vim.cmd('split')
  vim.cmd('wincmd j')
  vim.cmd('resize 20')
  vim.cmd('terminal ' .. args.args)
end, {nargs = '*'})

-- 起動時にインサートモードにする
vim.api.nvim_create_autocmd({ "TermOpen" }, {
  command = "startinsert",
})

