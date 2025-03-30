-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- 背景透過を常に適用する
-- vim.api.nvim_create_autocmd("ColorScheme", {
--   pattern = "*",
--   callback = function()
--     vim.cmd([[
--       highlight Normal guibg=NONE ctermbg=NONE
--       highlight NormalNC guibg=NONE ctermbg=NONE
--       highlight NormalFloat guibg=NONE ctermbg=NONE
--       highlight FloatBorder guibg=NONE ctermbg=NONE
--       highlight VertSplit guibg=NONE ctermbg=NONE
--     ]])
--   end,
-- })

vim.api.nvim_create_user_command("CountCleanTextLength", function()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local text = table.concat(lines, "\n")

  text = text:gsub("```.-```", "")
  text = text:gsub("`.-`", "")
  text = text:gsub("%[%^%d+%]", "")
  text = text:gsub("\n%[%^%d+%]:[^\n]*", "")
  text = text:gsub("<https?://[^>]+>", "")
  text = text:gsub("%[([^%]]-)%]%([^%)]+%)", "%1")
  text = text:gsub("#+", ""):gsub("%*%*", ""):gsub("%*", ""):gsub("_", ""):gsub("[%[%]%(%)]", ""):gsub("-", "")

  local clean = text:gsub("%s+", "")
  print("文字数（記法除去後）: " .. #clean)
end, {})

-- 任意：キーマップも Markdown のときだけ登録
vim.keymap.set("n", "<leader>mc", "<cmd>CountCleanTextLength<CR>", { desc = "🧮 Markdown文字数カウント" })
