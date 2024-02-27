-- Normal to Command
vim.keymap.set('n', ':', ';')
vim.keymap.set('n', ';', ':')

-- automatically joump to end of text you pasted
vim.keymap.set('v', 'y', 'y`]')
vim.keymap.set({ 'v', 'n' }, 'p', 'p`]')

vim.keymap.set('n', 'ZZ', '<NOP>')
vim.keymap.set('n', 'ZQ', '<NOP>')

-- do not overwrite default register
vim.keymap.set('n', 'x', '"_x')
vim.keymap.set('n', 'X', '"_X')
vim.keymap.set('n', 's', '"_s')

-- leader
vim.api.nvim_set_var('mapleader', ',')
vim.api.nvim_set_var('maplocalleader', '\\')

-- window
-- vim.keymap.set('n', '<leader>h', '<C-w><C-h>')
-- vim.keymap.set('n', '<leader>j', '<C-w><C-j>')
-- vim.keymap.set('n', '<leader>k', '<C-w><C-k>')
-- vim.keymap.set('n', '<leader>l', '<C-w><C-l>')

-- 画面分割
vim.keymap.set('n', 'ss', ':split<Return><C-w>w')
vim.keymap.set('n', 'sv', ':vsplit<Return><C-w>w')
-- アクティブウィンドウの移動
vim.keymap.set('n', 'sh', '<C-w>h')
vim.keymap.set('n', 'sk', '<C-w>k')
vim.keymap.set('n', 'sj', '<C-w>j')
vim.keymap.set('n', 'sl', '<C-w>l')

-- buffer
vim.keymap.set('n', '<Tab>', ':bnext<CR>')
vim.keymap.set('n', '<S-Tab>', ':bprev<CR>')