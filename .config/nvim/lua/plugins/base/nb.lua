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
        vim.cmd.edit(nb.get_note_path(item.full_id))
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

-- ノートを追加して開く
local function add_note()
  local nb = require("config.nb")
  vim.ui.input({ prompt = "Note title (empty for timestamp): " }, function(title)
    local note_id = nb.add_note(title)
    if note_id then
      local path = nb.get_note_path(note_id)
      if path and path ~= "" then
        vim.cmd.edit(path)
      end
    else
      vim.notify("Failed to add note", vim.log.levels.ERROR)
    end
  end)
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
    { "<leader>ni", import_image, desc = "nb import image" },
    { "<leader>nl", link_item, desc = "nb link" },
    { "<leader>np", pick_notes, desc = "nb picker" },
    { "<leader>ng", grep_notes, desc = "nb grep" },
  },
}
