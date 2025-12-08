-- snacks.nvimでノートをタイトル一覧から検索して開く
local function pick_notes()
  local nb = require("config.nb")
  local Snacks = require("snacks")
  local notes = nb.list_notes()
  if not notes then
    vim.notify("Failed to get notes", vim.log.levels.ERROR)
    return
  end

  -- ノート一覧をパース
  local items = {}
  for _, line in ipairs(notes) do
    local note_id, title = line:match("^%[(.-)%]%s+(.+)")
    if note_id then
      table.insert(items, {
        text = string.format("[%s] %s", note_id, title or "No title"),
        note_id = note_id,
      })
    end
  end

  -- ピッカーを表示
  Snacks.picker({
    title = "nb Notes",
    items = items,
    format = function(item)
      return { { item.text } }
    end,
    preview = function(ctx)
      local item = ctx.item
      if not item.file then
        item.file = nb.get_note_path(item.note_id)
      end
      return Snacks.picker.preview.file(ctx)
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        local path = nb.get_note_path(item.note_id)
        vim.cmd.edit(path)
      end
    end,
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

return {
  "folke/snacks.nvim",
  keys = {
    { "<leader>na", add_note, desc = "nb add" },
    { "<leader>np", pick_notes, desc = "nb picker" },
    { "<leader>ng", grep_notes, desc = "nb grep" },
  },
}
