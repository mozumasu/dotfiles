local M = {}

local function core()
  return require("nb.core")
end

-- picker 共通プレビュー（setup の preview オプションで差し替え可能）
local function preview(ctx)
  local item = ctx.item
  if item.is_folder or not item.file then
    return nil
  end
  local custom = require("nb.config").options.preview
  if custom then
    return custom(ctx)
  end
  return require("snacks").picker.preview.file(ctx)
end

local function format_note_item(item)
  local prefix = string.format("[%s]", item.notebook)
  local icon = ""
  if item.is_image then
    icon = " 🌄"
  elseif item.is_folder then
    icon = " 📂"
  end
  local folder_ctx = item.folder_path and (" " .. item.folder_path) or ""
  return { { prefix .. folder_ctx .. icon .. " " .. item.name } }
end

-- 現在のファイルが属するノートブックを取得
local function get_current_notebook()
  return core().notebook_of(vim.fn.expand("%:p"))
end

-- ノートをタイトル一覧から検索して開く（全ノートブック対応）
function M.pick()
  local nb = core()
  local Snacks = require("snacks")

  local items = nb.list_all_items()
  if not items or #items == 0 then
    vim.notify("No notes found", vim.log.levels.WARN)
    return
  end

  Snacks.picker({
    title = "nb Notes (All Notebooks)",
    items = items,
    format = format_note_item,
    preview = preview,
    confirm = function(picker, item)
      picker:close()
      if item and not item.is_folder and item.file then
        vim.cmd.edit(item.file)
      end
    end,
    actions = {
      delete_note = function(picker)
        local item = picker:current()
        if item then
          vim.ui.select({ "Yes", "No" }, {
            prompt = "Delete: [" .. item.notebook .. "] " .. item.name .. "?",
          }, function(choice)
            if choice == "Yes" then
              if nb.delete_note(item.full_id) then
                vim.notify("Deleted: " .. item.name, vim.log.levels.INFO)
                picker:close()
                M.pick()
              else
                vim.notify("Failed to delete", vim.log.levels.ERROR)
              end
            end
          end)
        end
      end,
    },
    win = {
      input = {
        keys = {
          ["<C-d>"] = { "delete_note", mode = { "n", "i" }, desc = "Delete note" },
        },
      },
    },
  })
end

-- ノートの内容をgrep検索
function M.grep()
  require("snacks").picker.grep({
    dirs = { core().dir() },
  })
end

-- 指定ノートブックにノートを追加して開く
local function add_note_to_notebook(notebook)
  local nb = core()
  vim.schedule(function()
    vim.cmd.startinsert()
  end)
  vim.ui.input({ prompt = "Note title (empty for timestamp): " }, function(title)
    if title == nil then
      return -- cancelled
    end
    local path = nb.add_note(title, notebook)
    if path and path ~= "" then
      vim.cmd.edit(path)
      -- ファイル末尾に移動してインサートモードに入る
      vim.cmd("normal! G")
      vim.cmd.startinsert({ bang = true })
    else
      vim.notify("Failed to add note", vim.log.levels.ERROR)
    end
  end)
end

-- ノートブックを選択してノートを追加
function M.add_select()
  local nb = core()
  local Snacks = require("snacks")
  local notebooks = nb.list_notebooks()
  local current_notebook = get_current_notebook()

  if not notebooks or #notebooks == 0 then
    vim.notify("No notebooks found", vim.log.levels.WARN)
    return
  end

  local items = {}
  local initial_idx = 1
  for i, name in ipairs(notebooks) do
    table.insert(items, { text = name, notebook = name })
    if name == current_notebook then
      initial_idx = i
    end
  end

  Snacks.picker({
    title = "Select Notebook",
    items = items,
    format = function(item)
      local marker = item.notebook == current_notebook and " (current)" or ""
      return { { "📓 " .. item.notebook .. marker } }
    end,
    on_show = function(picker)
      picker.list:view(initial_idx)
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        add_note_to_notebook(item.notebook)
      end
    end,
  })
end

-- ノートを追加して開く（現在のノートブックに追加）
function M.add()
  local current_notebook = get_current_notebook()

  if current_notebook then
    add_note_to_notebook(current_notebook)
  else
    -- nbディレクトリ外の場合はノートブック選択
    M.add_select()
  end
end

-- 画像をインポートしてマークダウンリンクを挿入
-- クリップボードに画像があればそれを優先、なければファイルパスを聞く
function M.import_image()
  local nb = core()
  local current_notebook = get_current_notebook()
  if not current_notebook then
    vim.notify("Not in nb directory", vim.log.levels.WARN)
    return
  end

  -- ファイル名プロンプト → import → リンク挿入の共通処理
  local function complete_import(image_path, cleanup_src, default_filename)
    local prompt = default_filename and "Filename (empty for timestamp): " or "Filename (empty to keep original): "
    vim.ui.input({ prompt = prompt }, function(new_filename)
      if (not new_filename or new_filename == "") and default_filename then
        new_filename = default_filename
      end
      local filename, err = nb.import_file(image_path, current_notebook, new_filename)
      if cleanup_src then
        os.remove(image_path)
      end
      if filename then
        local link = string.format("![%s](%s)", filename, filename)
        vim.api.nvim_put({ link }, "c", true, true)
        vim.notify("Imported: " .. filename, vim.log.levels.INFO)
      else
        vim.notify(err or "Failed to import image", vim.log.levels.ERROR)
      end
    end)
  end

  -- クリップボードに画像があれば一時ファイル経由で取り込む
  local ok, clipboard = pcall(require, "img-clip.clipboard")
  if ok and clipboard.content_is_image() then
    local tmp_path = vim.fn.tempname() .. ".png"
    if not clipboard.save_image(tmp_path) then
      vim.notify("Failed to save clipboard image", vim.log.levels.ERROR)
      return
    end
    complete_import(tmp_path, true, os.date(require("nb.config").options.timestamp_format) .. ".png")
    return
  end

  -- クリップボードに画像がなければファイルパスを聞く
  vim.ui.input({ prompt = "Image path: ", completion = "file" }, function(image_path)
    if not image_path or image_path == "" then
      return
    end
    complete_import(image_path, false, nil)
  end)
end

-- 現在のノートを別のノートブックに移動
function M.move()
  local nb = core()
  local Snacks = require("snacks")
  local current_notebook = get_current_notebook()

  if not current_notebook then
    vim.notify("Not in nb directory", vim.log.levels.WARN)
    return
  end

  -- 現在のファイル名からノートIDを取得
  local current_file = vim.fn.expand("%:p")
  local filename = vim.fn.fnamemodify(current_file, ":t") -- 拡張子付きのファイル名
  local current_note_id = current_notebook .. ":" .. filename

  local notebooks = nb.list_notebooks()
  if not notebooks or #notebooks == 0 then
    vim.notify("No notebooks found", vim.log.levels.WARN)
    return
  end

  -- 現在のノートブックを除外
  local items = {}
  for _, name in ipairs(notebooks) do
    if name ~= current_notebook then
      table.insert(items, { text = name, notebook = name })
    end
  end

  if #items == 0 then
    vim.notify("No other notebooks available", vim.log.levels.WARN)
    return
  end

  Snacks.picker({
    title = "Move to Notebook",
    items = items,
    format = function(item)
      return { { "📓 " .. item.notebook } }
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        local result = nb.move_note(current_note_id, item.notebook)
        if result then
          -- 移動後のパスを直接構築して開く
          local new_path = nb.dir() .. "/" .. item.notebook .. "/" .. filename
          if vim.fn.filereadable(new_path) == 1 then
            vim.cmd.edit(new_path)
            vim.notify("Moved to " .. item.notebook, vim.log.levels.INFO)
          else
            vim.notify("Moved but could not open new location", vim.log.levels.WARN)
          end
        else
          vim.notify("Failed to move note", vim.log.levels.ERROR)
        end
      end
    end,
  })
end

-- リンクを挿入（全ノートブック対応）
function M.link()
  local nb = core()
  local Snacks = require("snacks")
  local current_notebook = get_current_notebook()

  local items = nb.list_all_items()
  if not items or #items == 0 then
    vim.notify("No items found", vim.log.levels.WARN)
    return
  end

  Snacks.picker({
    title = "nb Link (All Notebooks)",
    items = items,
    format = format_note_item,
    preview = preview,
    confirm = function(picker, item)
      picker:close()
      if item then
        local link
        -- 異なるノートブックの場合は notebook:name 形式
        local needs_prefix = current_notebook and item.notebook ~= current_notebook
        if item.is_image then
          if needs_prefix then
            link = string.format("![%s](%s)", item.name, nb.browse_url(item.notebook, item.name))
          else
            link = string.format("![%s](%s)", item.name, item.name)
          end
        else
          if needs_prefix then
            link = string.format("[[%s:%s]]", item.notebook, item.name)
          else
            link = string.format("[[%s]]", item.name)
          end
        end
        vim.api.nvim_put({ link }, "c", true, true)
      end
    end,
  })
end

-- 現在のバッファのファイルを nb 配下の notebook へ移動（外部ファイルの取り込み）
function M.adopt_buffer()
  local nb = core()
  local Snacks = require("snacks")

  local current_file = vim.fn.expand("%:p")
  if current_file == "" or not vim.uv.fs_stat(current_file) then
    vim.notify("No file in current buffer", vim.log.levels.WARN)
    return
  end

  if current_file:match("^" .. vim.pesc(nb.dir())) then
    vim.notify("Already in nb directory — use move() to move between notebooks", vim.log.levels.WARN)
    return
  end

  -- 未保存変更があれば書き込んでから移動
  if vim.bo.modified then
    vim.cmd.write()
  end

  local notebooks = nb.list_notebooks()
  if not notebooks or #notebooks == 0 then
    vim.notify("No notebooks found", vim.log.levels.WARN)
    return
  end

  local items = {}
  for _, name in ipairs(notebooks) do
    table.insert(items, { text = name, notebook = name })
  end

  Snacks.picker({
    title = "Adopt to Notebook",
    items = items,
    format = function(item)
      return { { "📓 " .. item.notebook } }
    end,
    confirm = function(picker, item)
      picker:close()
      if not item then
        return
      end
      vim.ui.input({ prompt = "Title (empty to keep filename): " }, function(title)
        if title == nil then
          return -- cancelled
        end
        local old_buf = vim.api.nvim_get_current_buf()
        local new_path, err = nb.adopt_file(current_file, item.notebook, title)
        if not new_path then
          vim.notify("Adopt failed: " .. (err or "unknown"), vim.log.levels.ERROR)
          return
        end
        vim.cmd.edit(new_path)
        if vim.api.nvim_buf_is_valid(old_buf) and old_buf ~= vim.api.nvim_get_current_buf() then
          pcall(vim.api.nvim_buf_delete, old_buf, { force = true })
        end
        vim.notify("Adopted to " .. item.notebook, vim.log.levels.INFO)
      end)
    end,
  })
end

return M
