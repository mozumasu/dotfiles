local menuCommand = {}

local function actionsMenu(nd)
  local default_options = {
    results_title = 'NvimTree',
    finder = require('telescope.finders').new_table {
      results = menuCommand,
      entry_maker = function(menu_item)
        return {
          value = menu_item,
          ordinal = menu_item.name,
          display = menu_item.name,
        }
      end,
    },
    sorter = require('telescope.sorters').get_generic_fuzzy_sorter(),
    attach_mappings = function(prompt_buffer_number)
      local actions = require 'telescope.actions'
      actions.select_default:replace(function()
        actions.close(prompt_buffer_number)
        require('telescope.actions.state').get_selected_entry().value.handler(nd)
      end)
      return true
    end,
  }

  require('telescope.pickers')
      .new({ prompt_title = 'Command', layout_config = { width = 0.3, height = 0.5 } }, default_options):find()
end

local api = require 'nvim-tree.api'
local tree, fs, node = api.tree, api.fs, api.node

local command = {
  { '',      tree.change_root_to_node,       'CD' },
  { '',      node.open.replace_tree_buffer,  'Open: In Place' },
  { '',      node.show_info_popup,           'Info' },
  { '',      fs.rename_sub,                  'Rename: Omit Filename' },
  { '',      node.open.tab,                  'Open: New Tab' },
  { '',      node.open.vertical,             'Open: Vertical Split' },
  { '',      node.open.horizontal,           'Open: Horizontal Split' },
  { '<BS>',  node.navigate.parent_close,     'Close Directory' },
  { '<CR>',  node.open.edit,                 'Open' },
  { '<Tab>', node.open.preview,              'Open Preview' },
  { '>',     node.navigate.sibling.next,     'Next Sibling' },
  { '<',     node.navigate.sibling.prev,     'Previous Sibling' },
  { '.',     node.run.cmd,                   'Run Command' },
  { '-',     tree.change_root_to_parent,     'Up' },
  { '',      fs.create,                      'Create' },
  { '',      api.marks.bulk.move,            'Move Bookmarked' },
  { 'B',     tree.toggle_no_buffer_filter,   'Toggle No Buffer' },
  { '',      fs.copy.node,                   'Copy' },
  { 'C',     tree.toggle_git_clean_filter,   'Toggle Git Clean' },
  { '[c',    node.navigate.git.prev,         'Prev Git' },
  { ']c',    node.navigate.git.next,         'Next Git' },
  { '',      fs.remove,                      'Delete' },
  { '',      fs.trash,                       'Trash' },
  { 'E',     tree.expand_all,                'Expand All' },
  { '',      fs.rename_basename,             'Rename: Basename' },
  { ']e',    node.navigate.diagnostics.next, 'Next Diagnostic' },
  { '[e',    node.navigate.diagnostics.prev, 'Prev Diagnostic' },
  { 'F',     api.live_filter.clear,          'Clean Filter' },
  { 'f',     api.live_filter.start,          'Filter' },
  { 'g?',    tree.toggle_help,               'Help' },
  { 'gy',    fs.copy.absolute_path,          'Copy Absolute Path' },
  { 'H',     tree.toggle_hidden_filter,      'Toggle Dotfiles' },
  { 'I',     tree.toggle_gitignore_filter,   'Toggle Git Ignore' },
  { 'J',     node.navigate.sibling.last,     'Last Sibling' },
  { 'K',     node.navigate.sibling.first,    'First Sibling' },
  { 'm',     api.marks.toggle,               'Toggle Bookmark' },
  { 'o',     node.open.edit,                 'Open' },
  { 'O',     node.open.no_window_picker,     'Open: No Window Picker' },
  { '',      fs.paste,                       'Paste' },
  { 'P',     node.navigate.parent,           'Parent Directory' },
  { 'q',     tree.close,                     'Close' },
  { 'r',     fs.rename,                      'Rename' },
  { 'R',     tree.reload,                    'Refresh' },
  { 's',     node.run.system,                'Run System' },
  { 'S',     tree.search_node,               'Search' },
  { 'U',     tree.toggle_custom_filter,      'Toggle Hidden' },
  { 'W',     tree.collapse_all,              'Collapse' },
  { '',      fs.cut,                         'Cut' },
  { 'y',     fs.copy.filename,               'Copy Name' },
  { 'Y',     fs.copy.relative_path,          'Copy Relative Path' },

  --{ '<2-LeftMouse>',  node.open.edit,        'Open' },

  --{ '<Space>', actionsMenu,                  'Command' },
}

local function createTreeActions()
  for _, cmd in pairs(command) do
    table.insert(menuCommand, { name = cmd[3], handler = cmd[2] })
  end
end

createTreeActions()

local M = {}

function M.on_attach(bufnr)
  local opts = function(desc)
    return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, nowait = true }
  end

  for _, cmd in pairs(command) do
    if (string.len(cmd[1]) > 0) then
      vim.keymap.set('n', cmd[1], cmd[2], opts(cmd[3]))
    end
  end
end

return M