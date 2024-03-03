require('nvim-tree').setup {
    sort_by = 'extension',
  
    view = {
      width = '20%',
      side = 'left',
      signcolumn = 'no',
    },
  
    renderer = {
      group_empty = true, -- 空のディレクトリをグループ化する
      highlight_git = true,
      highlight_opened_files = 'name',
      icons = {
        glyphs = {
          git = {
            unstaged = '!', renamed = '»', untracked = '?', deleted = '✘',
            staged = '✓', unmerged = '', ignored = '◌',
          },
        },
      },
    },

    filters = {
        dotfiles = true, -- 隠しファイルを表示
    },
  
    actions = {
      expand_all = {
        max_folder_discovery = 100,
        exclude = { '.git', 'target', 'build' },
      },
    },
  
    on_attach = require('extensions.nvim-tree-actions').on_attach,
  }
  
  vim.api.nvim_create_user_command('Ex', function() vim.cmd.NvimTreeToggle() end, {})

  -- keymap
  vim.keymap.set('n', '<leader>ex', vim.cmd.NvimTreeToggle)