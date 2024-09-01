require('copilot').setup {
    suggestion = { enabled = false },
    panel = { enabled = false },
  
    copilot_node_command = 'node',
  }
  
  vim.api.nvim_create_user_command('Takeoff', function()
    vim.notify 'Cleared for Takeoff!'
  end, {})
