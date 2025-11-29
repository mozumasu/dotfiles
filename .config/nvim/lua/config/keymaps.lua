-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local keymap = vim.keymap.set
local keydel = vim.keymap.del

local opts = { noremap = true, silent = true }
local util = require("lazyvim.util")

-- emacs like keybind
keymap("i", "<C-a>", "<Home>", opts)
keymap("i", "<C-e>", "<End>", opts)

-- Control + I と Tab をデフォルトの状態に戻す
vim.api.nvim_set_keymap("n", "<C-i>", "<C-i>", { noremap = true })
vim.api.nvim_set_keymap("i", "<C-i>", "<C-i>", { noremap = true })

-- Increment / Decrement
keymap("n", "+", "<C-a>", opts)
keymap("n", "-", "<C-x>", opts)

-- Tab
keymap("n", "<tab>", ":tabnext<Return>", opts)
keymap("n", "<s-tab>", ":tabprev<Return>", opts)

-- Split window
keymap("n", "ss", ":split<Return>", opts)
keymap("n", "sv", ":vsplit<Return>", opts)
-- Move window
keymap("n", "sh", "<C-w>h")
keymap("n", "sk", "<C-w>k")
keymap("n", "sj", "<C-w>j")
keymap("n", "sl", "<C-w>l")
-- Resize window
keymap("n", "<C-w><left>", "<C-w><")
keymap("n", "<C-w><right>", "<C-w>>")
keymap("n", "<C-w><up>", "<C-w>+")
keymap("n", "<C-w><down>", "<C-w>-")

-- Diagnostics
keymap("n", "<C-j>", function()
  vim.diagnostic.goto_next()
end, opts)

-- lazydocker
if vim.fn.executable("lazydocker") == 1 then
  vim.keymap.set("n", "<leader>d", function()
    util.terminal("lazydocker", { esc_esc = false, ctrl_hjkl = false, border = "rounded" })
  end, { desc = "LazyDocker" })
end

-- terminal
keymap("n", "<c-/>", function()
  Snacks.terminal()
end, { desc = "Terminal (Root Dir)" })
keymap("n", "<c-_>", function()
  Snacks.terminal(nil, { cwd = LazyVim.root() })
end, { desc = "Terminal (cwd)" })

-- disable default keymappings
keydel("n", "<leader>ft", { desc = "Terminal (cwd)" })
keydel("n", "<leader>fT", { desc = "Terminal (root)" })

-- Notification History: <leader>n -> <leader>nn
keydel("n", "<leader>n")
keymap("n", "<leader>nn", function()
  Snacks.notifier.show_history()
end, { desc = "Notification History" })

-- Get git root from current buffer
local function get_git_root()
  local buf_dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":h")
  local git_root = vim.fn.systemlist("git -C " .. vim.fn.shellescape(buf_dir) .. " rev-parse --show-toplevel")[1]
  return (vim.v.shell_error == 0 and git_root) or LazyVim.root.get({ buf = 0 })
end

-- Swap LazyGit keymaps (gg: cwd, gG: root)
keymap("n", "<leader>gg", function()
  Snacks.lazygit({ cwd = vim.fn.getcwd() })
end, { desc = "LazyGit (cwd)" })
keymap("n", "<leader>gG", function()
  Snacks.lazygit({ cwd = get_git_root() })
end, { desc = "LazyGit (Root Dir)" })

-- Find Files from project root
keymap("n", "<leader><leader>", function()
  local cwd = get_git_root()
  local hidden = cwd:match("dotfiles$") ~= nil
  Snacks.picker.files({ cwd = cwd, hidden = hidden })
end, { desc = "Find Files (Root Dir)" })

-- Grep from project root
keymap("n", "<leader>/", function()
  local cwd = get_git_root()
  local hidden = cwd:match("dotfiles$") ~= nil
  Snacks.picker.grep({ cwd = cwd, hidden = hidden })
end, { desc = "Grep (Root Dir)" })

-- browse under cursor
keymap("n", "gh", function()
  local cfile = vim.fn.expand("<cfile>")
  if cfile:match("^https?://") then
    os.execute("open '" .. cfile .. "'") -- for macOS
  else
    vim.cmd("normal! gF!")
  end
end, { desc = "link open" })

-- browse github repogitory
keymap("n", "<leader>gR", function()
  local github_repogitory_name = vim.fn.expand("<cfile>")
  if github_repogitory_name:match(".+/[^/]+") then
    os.execute("open 'https://github.com/" .. github_repogitory_name .. "'") -- for macOS
  else
    vim.cmd("normal!, gF!")
  end
end, { desc = "GitHub repogitory" })

-- substitution word under cursor
keymap("n", "#", function()
  local current_word = vim.fn.expand("<cword>")
  vim.api.nvim_feedkeys(":%s/" .. current_word .. "//g", "n", false)
  -- :%s/word/CURSOR/g
  local ll = vim.api.nvim_replace_termcodes("<Left><Left>", true, true, true)
  vim.api.nvim_feedkeys(ll, "n", false)
  vim.opt.hlsearch = true
end, { desc = "substitusion word under cursor" })

-- say command
keymap("n", "<leader>say", function()
  local current_word = vim.fn.expand("<cword>")
  vim.api.nvim_feedkeys(":!say -v Ava " .. current_word .. "\n", "n", false)
end, { desc = "say command" })
