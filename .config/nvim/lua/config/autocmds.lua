-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- 背景透過を維持（Zenモードで:w後も透明を保つ）
local function apply_transparent_bg()
  vim.cmd([[
    highlight Normal guibg=NONE ctermbg=NONE
    highlight NormalNC guibg=NONE ctermbg=NONE
    highlight NormalFloat guibg=NONE ctermbg=NONE
    highlight FloatBorder guibg=NONE ctermbg=NONE
    highlight VertSplit guibg=NONE ctermbg=NONE
    highlight SnacksBackdrop guibg=NONE ctermbg=NONE
    highlight SnacksNormal guibg=NONE ctermbg=NONE
    highlight SnacksNormalNC guibg=NONE ctermbg=NONE
  ]])
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    pcall(vim.api.nvim_win_set_option, win, "winblend", 0)
  end
end

vim.api.nvim_create_autocmd({ "BufWritePost", "ColorScheme" }, {
  pattern = "*",
  callback = function()
    vim.schedule(apply_transparent_bg)
  end,
})

vim.api.nvim_create_user_command("CountCleanTextLength", function()
  local bufnr = 0
  local mode = vim.fn.mode()
  local lines = {}
  local context = ""

  if mode == "v" or mode == "V" or mode == "\22" then
    -- 選択範囲取得
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")

    local start_row = start_pos[2] - 1
    local start_col = start_pos[3] - 1
    local end_row = end_pos[2] - 1
    local end_col = end_pos[3]

    lines = vim.api.nvim_buf_get_text(bufnr, start_row, start_col, end_row, end_col, {})
    context = "選択範囲"
  else
    lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    context = "ファイル全体"
  end

  local text = table.concat(lines, "\n")

  -- Markdownの記法など除去
  text = text:gsub("```.-```", "")
  text = text:gsub("`.-`", "")
  text = text:gsub("%[%^%d+%]", "")
  text = text:gsub("\n%[%^%d+%]:[^\n]*", "")
  text = text:gsub("<https?://[^>]+>", "")
  text = text:gsub("%[([^%]]-)%]%([^%)]+%)", "%1")
  text = text:gsub("#+", ""):gsub("%*%*", ""):gsub("%*", ""):gsub("_", ""):gsub("[%[%]%(%)]", ""):gsub("-", "")

  local clean = text:gsub("%s+", "")
  print(context .. "の文字数（記法除去後）: " .. #clean)
end, {})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.keymap.set({ "n", "v" }, "<leader>mc", "<cmd>CountCleanTextLength<CR>", {
      desc = "🧮 Markdown文字数カウント",
      buffer = true,
    })
  end,
})

vim.api.nvim_create_user_command("InsertDatetime", function()
  local handle = io.popen('date "+%Y-%m-%d %H:%M:%S"')
  if not handle then
    print("日付取得に失敗")
    return
  end

  local result = handle:read("*a")
  handle:close()
  result = result:gsub("%s+$", "") -- 改行除去

  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1 -- Lua は 0-indexed

  vim.api.nvim_buf_set_text(0, row, col, row, col, { result })
end, {})
