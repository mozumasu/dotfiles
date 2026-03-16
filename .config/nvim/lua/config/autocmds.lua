-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- octo.nvim: octo://バッファでスワップファイルを無効化（E325: ATTENTION対策）
-- BufNew: バッファ名が設定された直後（nvim_buf_set_nameのタイミング）に発火
vim.api.nvim_create_autocmd({ "BufNew", "BufAdd", "BufWinEnter" }, {
  pattern = "octo://*",
  callback = function()
    vim.opt_local.swapfile = false
  end,
})

-- SpellCap（青い波線）を無効化
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    vim.api.nvim_set_hl(0, "SpellCap", {})
  end,
})
vim.api.nvim_set_hl(0, "SpellCap", {})

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
    vim.keymap.set("n", "<leader>mo", function()
      local buf = vim.api.nvim_get_current_buf()
      local ok, parser = pcall(vim.treesitter.get_parser, buf, "markdown")
      if not ok or not parser then
        vim.notify("treesitter markdown parser が利用できません", vim.log.levels.WARN)
        return
      end
      parser:parse(true)

      local query = vim.treesitter.query.parse("markdown", "(atx_heading) @heading")
      local items = {}
      for _, tree in ipairs(parser:trees()) do
        for _, node in query:iter_captures(tree:root(), buf) do
          local row = node:start()
          local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
          local level, text = line:match("^(#+)%s+(.+)$")
          if level and text then
            items[#items + 1] = {
              text = string.rep("  ", #level - 1) .. text,
              pos = { row + 1, 0 },
              buf = buf,
            }
          end
        end
      end

      Snacks.picker.pick({
        title = "Markdown Outline",
        items = items,
        format = "text",
        sort = false,
      })
    end, {
      desc = "Markdown outline (treesitter)",
      buffer = true,
    })
    vim.keymap.set("n", "so", "<cmd>Arto<CR>", {
      desc = "Open file in Arto",
      buffer = true,
    })
  end,
})

-- [[notebook:name]] 形式のリンクにジャンプ（LspAttach後に設定してLazyVimのgdを上書き）
vim.api.nvim_create_autocmd("LspAttach", {
  pattern = "*.md",
  callback = function(args)
    vim.keymap.set("n", "gd", function()
      local line = vim.api.nvim_get_current_line()
      local col = vim.api.nvim_win_get_cursor(0)[2] + 1

      -- [[notebook:name]] 形式のリンクを検出（コロンを含むもののみ）
      local search_start = 1
      while true do
        local start_pos, end_pos, link = line:find("%[%[([^%]]+:[^%]]+)%]%]", search_start)
        if not start_pos then
          break
        end
        if col >= start_pos and col <= end_pos then
          local path = require("config.nb").get_note_path(link)
          if path and path ~= "" then
            vim.cmd.edit(path)
            return
          end
        end
        search_start = end_pos + 1
      end

      vim.lsp.buf.definition()
    end, { buffer = args.buf, desc = "Go to nb link or definition" })
  end,
})

-- nb形式のリンク（notebook:note）のMarksman警告を無視
local original_diagnostics_handler = vim.lsp.handlers["textDocument/publishDiagnostics"]
vim.lsp.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
  if result and result.diagnostics then
    result.diagnostics = vim.tbl_filter(function(diagnostic)
      -- Marksmanのnbリンクエラーを除外（例: "Link to non-existent document 'home:note'"）
      if diagnostic.source == "Marksman" then
        local msg = diagnostic.message or ""
        if msg:match("Link to non%-existent document '[%w_%-]+:") then
          return false
        end
      end
      return true
    end, result.diagnostics)
  end
  return original_diagnostics_handler(err, result, ctx, config)
end

vim.api.nvim_create_user_command("InsertDatetime", function()
  -- io.popen('date ...') の代わりに vim.fn.strftime を使用（外部プロセス不要）
  local result = vim.fn.strftime("%Y-%m-%d %H:%M:%S")
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1 -- Lua は 0-indexed
  vim.api.nvim_buf_set_text(0, row, col, row, col, { result })
end, {})

-- ヤンク時のみクリップボード連携（削除などは除外）
-- _last_vim_yank: vim内でyankした最後の内容を記録（外部コピーとの区別用）
local _last_vim_yank = ""
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("yank_to_clipboard", { clear = true }),
  callback = function()
    if vim.v.event.operator == "y" then
      local text = vim.fn.getreg('"')
      vim.fn.setreg("+", text)
      _last_vim_yank = text
    end
  end,
})

-- 外部アプリでコピーした内容をpで貼り付けられるようにする
-- クリップボードがvim内のyankと異なる場合（＝外部でコピーされた場合）のみ無名レジスタに同期
vim.api.nvim_create_autocmd("FocusGained", {
  group = vim.api.nvim_create_augroup("clipboard_to_unnamed", { clear = true }),
  callback = function()
    local clip = vim.fn.getreg("+")
    if clip ~= "" and clip ~= _last_vim_yank then
      vim.fn.setreg('"', clip)
    end
  end,
})

-- :quit時に特殊ウィンドウ(quickfix, help等)のみが残っている場合は自動で閉じる
-- ref: https://zenn.dev/vim_jp/articles/ff6cd224fab0c7
vim.api.nvim_create_autocmd("QuitPre", {
  callback = function()
    local current_win = vim.api.nvim_get_current_win()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if win ~= current_win then
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].buftype == "" then
          return
        end
      end
    end
    vim.cmd.only({ bang = true })
  end,
})

-- Generate Co-Authored-By trailer and insert at cursor position
-- Usage: :CoAuthoredBy <github-username>
vim.api.nvim_create_user_command("CoAuthoredBy", function(opts)
  local username = opts.args
  if username == "" then
    vim.notify("Usage: :CoAuthoredBy <github-username>", vim.log.levels.ERROR)
    return
  end

  local cmd = string.format(
    [[gh api /users/%s -q '"Co-Authored-By: \(.name) <\(.id)+\(.login)@users.noreply.github.com>"']],
    username
  )
  -- 非同期実行（GitHub API呼び出しのフリーズ防止、タイムアウト10秒）
  vim.notify("Fetching user info for " .. username .. "...", vim.log.levels.INFO)
  vim.system({ "sh", "-c", cmd }, { text = true, timeout = 10000 }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        vim.notify("Failed to get user info: " .. (result.stderr or ""), vim.log.levels.ERROR)
        return
      end
      local text = result.stdout:gsub("\n$", "")
      vim.api.nvim_put({ text }, "l", true, true)
      vim.notify("Inserted: " .. text, vim.log.levels.INFO)
    end)
  end)
end, {
  nargs = 1,
  desc = "Generate Co-Authored-By trailer from GitHub username",
})

-- Open file in Arto (markdown editor)
vim.api.nvim_create_user_command("Arto", function(opts)
  local path = opts.args ~= "" and vim.fn.fnamemodify(opts.args, ":p") or vim.fn.expand("%:p")
  vim.system({ "open", "-a", "Arto", path })
end, {
  nargs = "?",
  complete = "file",
  desc = "Open file in Arto",
})
