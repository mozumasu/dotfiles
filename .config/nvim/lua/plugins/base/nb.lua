-- snacks.nvimでノートをタイトル一覧から検索して開く（全ノートブック対応）
local function pick_notes()
  local nb = require("config.nb")
  local Snacks = require("snacks")
  local items = nb.list_all_items()

  if not items or #items == 0 then
    vim.notify("No notes found", vim.log.levels.WARN)
    return
  end

  Snacks.picker({
    title = "nb Notes (All Notebooks)",
    items = items,
    format = function(item)
      local prefix = string.format("[%s]", item.notebook)
      local icon = ""
      if item.is_image then
        icon = " 🌄"
      elseif item.is_folder then
        icon = " 📂"
      end
      return { { prefix .. icon .. " " .. item.name } }
    end,
    preview = function(ctx)
      local item = ctx.item
      if item.is_folder then
        return nil
      end
      if not item.file then
        item.file = nb.get_note_path(item.full_id)
      end
      return Snacks.picker.preview.file(ctx)
    end,
    confirm = function(picker, item)
      picker:close()
      if item and not item.is_folder then
        local path = nb.get_note_path(item.full_id)
        if path and path ~= "" then
          vim.cmd.edit(path)
        else
          vim.notify("Failed to get note path: " .. item.full_id, vim.log.levels.ERROR)
        end
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
                pick_notes()
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

-- snacks.nvimでノートの内容をgrep検索
local function grep_notes()
  local nb = require("config.nb")
  local Snacks = require("snacks")
  Snacks.picker.grep({
    dirs = { nb.get_nb_dir() },
  })
end

-- 現在のファイルが属するノートブックを取得
local function get_current_notebook()
  local nb = require("config.nb")
  local current_file = vim.fn.expand("%:p")
  local nb_dir = nb.get_nb_dir()

  if not current_file:match("^" .. vim.pesc(nb_dir)) then
    return nil
  end

  -- nbディレクトリからの相対パスを取得し、最初のディレクトリ名を返す
  local relative = current_file:sub(#nb_dir + 2) -- +2 for trailing slash
  local notebook = relative:match("^([^/]+)/")
  return notebook
end

-- 指定ノートブックにノートを追加して開く
local function add_note_to_notebook(notebook)
  local nb = require("config.nb")
  vim.schedule(function()
    vim.cmd.startinsert()
  end)
  vim.ui.input({ prompt = "Note title (empty for timestamp): " }, function(title)
    if title == nil then
      return -- cancelled
    end
    local note_id = nb.add_note(title, notebook)
    if note_id then
      local path = nb.get_note_path(note_id)
      if path and path ~= "" then
        vim.cmd.edit(path)
        -- ファイル末尾に移動してインサートモードに入る
        vim.cmd("normal! G")
        vim.cmd.startinsert({ bang = true })
      end
    else
      vim.notify("Failed to add note", vim.log.levels.ERROR)
    end
  end)
end

-- ノートブックを選択してノートを追加
local function add_note_select()
  local nb = require("config.nb")
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
local function add_note()
  local current_notebook = get_current_notebook()

  if current_notebook then
    add_note_to_notebook(current_notebook)
  else
    -- nbディレクトリ外の場合はノートブック選択
    add_note_select()
  end
end

-- 画像をインポートしてマークダウンリンクを挿入
local function import_image()
  local nb = require("config.nb")
  vim.ui.input({ prompt = "Image path: ", completion = "file" }, function(image_path)
    if not image_path or image_path == "" then
      return
    end

    -- 新しいファイル名を入力（空ならそのまま）
    vim.ui.input({ prompt = "New filename (empty to keep original): " }, function(new_filename)
      local note_id, result = nb.import_image(image_path, new_filename)
      if note_id then
        local filename = result
        local link = string.format("![%s](%s)", filename, filename)
        vim.api.nvim_put({ link }, "c", true, true)
        vim.notify("Imported: " .. filename, vim.log.levels.INFO)
      else
        vim.notify(result or "Failed to import image", vim.log.levels.ERROR)
      end
    end)
  end)
end

-- 現在のノートを別のノートブックに移動
local function move_note()
  local nb = require("config.nb")
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
          local nb_dir = nb.get_nb_dir()
          local new_path = nb_dir .. "/" .. item.notebook .. "/" .. filename
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
local function link_item()
  local nb = require("config.nb")
  local Snacks = require("snacks")
  local items = nb.list_all_items()
  local current_notebook = get_current_notebook()

  if not items or #items == 0 then
    vim.notify("No items found", vim.log.levels.WARN)
    return
  end

  Snacks.picker({
    title = "nb Link (All Notebooks)",
    items = items,
    format = function(item)
      local prefix = string.format("[%s]", item.notebook)
      local icon = ""
      if item.is_image then
        icon = " 🌄"
      elseif item.is_folder then
        icon = " 📂"
      end
      return { { prefix .. icon .. " " .. item.name } }
    end,
    preview = function(ctx)
      local item = ctx.item
      if item.is_folder then
        return nil
      end
      if not item.file then
        item.file = nb.get_note_path(item.full_id)
      end
      return Snacks.picker.preview.file(ctx)
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        local link
        -- 異なるノートブックの場合は notebook:name 形式
        local needs_prefix = current_notebook and item.notebook ~= current_notebook
        if item.is_image then
          if needs_prefix then
            link = string.format("![%s](http://localhost:6789/--original/%s/%s)", item.name, item.notebook, item.name)
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

return {
  "folke/snacks.nvim",
  keys = {
    { "<leader>na", add_note, desc = "nb add" },
    { "<leader>nA", add_note_select, desc = "nb add (select notebook)" },
    { "<leader>ni", import_image, desc = "nb import image" },
    { "<leader>nl", link_item, desc = "nb link" },
    { "<leader>nm", move_note, desc = "nb move to notebook" },
    { "<leader>np", pick_notes, desc = "nb picker" },
    { "<leader>ng", grep_notes, desc = "nb grep" },
  },
}
