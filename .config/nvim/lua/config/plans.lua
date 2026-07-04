-- Claude Code の plansDirectory（claude-code.nix で `./plans` を設定）を扱う個人用モジュール
local M = {}

function M.get_plans_dir()
  return vim.fn.expand("~/dotfiles/plans")
end

-- plans/*.md を mtime 降順で取得
function M.list_plans()
  local dir = M.get_plans_dir()
  local handle = vim.uv.fs_scandir(dir)
  if not handle then
    return {}
  end
  local items = {}
  while true do
    local name, type = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end
    if type == "file" and name:match("%.md$") then
      local path = dir .. "/" .. name
      local stat = vim.uv.fs_stat(path)
      table.insert(items, {
        name = name,
        file = path,
        title = require("nb").md_title(path) or name,
        mtime = stat and stat.mtime.sec or 0,
        text = name,
      })
    end
  end
  table.sort(items, function(a, b)
    return a.mtime > b.mtime
  end)
  return items
end

-- 最新の plan を開く
function M.open_latest()
  local plans = M.list_plans()
  if #plans == 0 then
    vim.notify("No plans found in " .. M.get_plans_dir(), vim.log.levels.WARN)
    return
  end
  vim.cmd.edit(plans[1].file)
end

-- plansDirectory のファイルを picker から選択して開く
function M.picker()
  local Snacks = require("snacks")
  local items = M.list_plans()
  if #items == 0 then
    vim.notify("No plans found in " .. M.get_plans_dir(), vim.log.levels.WARN)
    return
  end

  Snacks.picker({
    title = "Plans",
    items = items,
    format = function(item)
      return { { "📋 " .. item.title }, { "  " .. item.name, "Comment" } }
    end,
    preview = function(ctx)
      return Snacks.picker.preview.file(ctx)
    end,
    confirm = function(picker, item)
      picker:close()
      if item and item.file then
        vim.cmd.edit(item.file)
      end
    end,
  })
end

return M
