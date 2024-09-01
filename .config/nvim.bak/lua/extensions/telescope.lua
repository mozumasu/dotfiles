local telescope = require 'telescope'
local themes = require 'telescope.themes'

telescope.setup {
  defaults = {
    mappings = {
      i = {
        ['<C-h>'] = 'which_key',
        ['<esc>'] = require('telescope.actions').close,
        ['<C-[>'] = require('telescope.actions').close,
      },
      n = {
        ['<C-h>'] = 'which_key',
      }
    },
    winblend = 20,
  },
  extensions = {
    fzf = {
      fuzzy = true,                   -- false will only do exact matching
      override_generic_sorter = true, -- override the generic sorter
      override_file_sorter = true,    -- override the file sorter
      case_mode = "smart_case",       -- or "ignore_case" or "respect_case"
      -- the default case_mode is "smart_case"
    },
  },
}
telescope.load_extension 'fzf'

local builtin = require 'telescope.builtin'

vim.keymap.set('n', '<leader>ff', builtin.find_files)
vim.keymap.set('n', '<leader>fg', builtin.live_grep)
vim.keymap.set('n', '<leader>fb', builtin.buffers)
vim.keymap.set('n', '<leader>fh', builtin.help_tags)
-- vim.keymap.set('n', '<leader>h', function()
--   builtin.help_tags(themes.get_ivy())
-- end)