local cmp = require 'cmp'
local luasnip = require 'luasnip'

local function has_words_before()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match '%s' == nil
end

local function has_copilot()
  if vim.api.nvim_buf_get_option(0, 'buftype') == 'prompt' then
    return false
  end
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_text(0, line - 1, 0, line - 1, col, {})[1]:match '^%s*$' == nill
end

local M = {}

M.tab = function(fallback)
  if cmp.visible() then
    cmp.select_next_item(has_copilot() and { behavior = cmp.SelectBehavior.Select } or {})
    return
  end

  if luasnip.expand_or_jumpable() then
    luasnip.expand_or_jump()
    return
  end

  if has_words_before() then
    cmp.complete()
    return
  end

  fallback()
end

M.shift_tab = function(fallback)
  if cmp.visible() then
    cmp.select_prev_item()
    return
  end

  if luasnip.jumpable(-1) then
    luasnip.jump(-1)
    return
  end

  fallback()
end

return M
