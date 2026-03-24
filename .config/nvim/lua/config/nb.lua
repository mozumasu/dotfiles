local M = {}

-- nbコマンドのプレフィックス（TERM=dumbでANSIエスケープを完全無効化）
local NB_CMD = "TERM=dumb NB_EDITOR=: NO_COLOR=1 nb"

-- フォルダ再帰展開の最大深度（無限再帰防止）
local MAX_FOLDER_DEPTH = 5

-- nbのノートディレクトリパスを取得
function M.get_nb_dir()
  -- nbのディレクトリパスに合わせて変更してください
  return vim.fn.expand("~/src/github.com/mozumasu/nb")
end

-- nbコマンドを実行（タイムアウト10秒でハング防止）
function M.run_cmd(args)
  local cmd = NB_CMD .. " " .. args
  local result = vim.system({ "sh", "-c", cmd }, { text = true, timeout = 10000 }):wait()
  if result.code ~= 0 then
    return nil
  end
  local output = {}
  for line in result.stdout:gmatch("[^\r\n]+") do
    table.insert(output, line)
  end
  return #output > 0 and output or nil
end

-- リスト行をパースして構造化データを返す
-- 例: "[1] 🌄 image.png" -> { note_id = "1", name = "image.png", is_image = true }
-- 例: "[2] ノートタイトル" -> { note_id = "2", name = "ノートタイトル", is_image = false }
function M.parse_list_item(line)
  local note_id = line:match("^%[(.-)%]")
  if not note_id then
    return nil
  end

  local is_image = line:match("🌄") ~= nil
  local name
  if is_image then
    name = line:match("%[%d+%]%s*🌄%s*(.+)$")
  else
    name = line:match("%[%d+%]%s*(.+)$")
  end

  if not name then
    return nil
  end

  return {
    note_id = note_id,
    name = vim.trim(name),
    is_image = is_image,
    text = line,
  }
end

-- パース済みアイテム一覧を取得
function M.list_items()
  local output = M.run_cmd("list --no-color")
  if not output then
    return nil
  end

  local items = {}
  for _, line in ipairs(output) do
    local item = M.parse_list_item(line)
    if item then
      table.insert(items, item)
    end
  end
  return items
end

-- nbノートのタイトルを取得する関数（bufferline用）
function M.get_title(filepath)
  local nb_dir = M.get_nb_dir()
  if not filepath:match("^" .. nb_dir) then
    return nil
  end

  local file = io.open(filepath, "r")
  if not file then
    return nil
  end

  local first_line = file:read("*l")
  file:close()

  if first_line then
    return first_line:match("^#%s+(.+)")
  end
  return nil
end

-- ノートIDからファイルパスを取得
function M.get_note_path(note_id)
  local escaped_id = vim.fn.shellescape(note_id)
  local output = M.run_cmd("show --path " .. escaped_id)
  if output and output[1] then
    return vim.trim(output[1])
  end
  return ""
end

-- ノートを追加してIDを返す（notebook指定可能）
function M.add_note(title, notebook)
  local timestamp = os.date("%Y%m%d%H%M%S")
  local note_title = title and title ~= "" and title or os.date("%Y-%m-%d %H:%M:%S")
  local escaped_title = note_title:gsub('"', '\\"')

  local cmd_prefix = notebook and (notebook .. ":") or ""
  local args = string.format('%sadd --no-color --filename "%s.md" --title "%s"', cmd_prefix, timestamp, escaped_title)

  local output = M.run_cmd(args)
  if not output then
    return nil
  end

  -- 追加されたノートのIDを取得
  -- 出力形式: "Added: [85] file.md" または "Added: [log:41] log:file.md"
  for _, line in ipairs(output) do
    -- [notebook:数字] または [数字] 形式をサポート
    local note_id = line:match("%[([%w]+:%d+)%]") or line:match("%[(%d+)%]")
    if note_id then
      -- 既に notebook:id 形式ならそのまま返す
      if note_id:find(":") then
        return note_id
      end
      -- notebook指定時は notebook:id 形式で返す
      if notebook then
        return notebook .. ":" .. note_id
      end
      return note_id
    end
  end
  return nil
end

-- 画像をnbにインポートする
function M.import_image(image_path, new_filename)
  if not image_path or image_path == "" then
    return nil, "No path provided"
  end

  -- パスをクリーンアップ: 空白/改行/クォート除去、エスケープされたスペースを復元
  local cleaned_path = image_path
    :gsub("^[%s\n]*['\"]?", "")
    :gsub("['\"]?[%s\n]*$", "")
    :gsub("/ ([^/])", " %1") -- Vim補完で「\ 」が「/ 」に変換される問題を修正
    :gsub("\\ ", " ")

  local expanded_path = vim.fn.resolve(vim.fn.fnamemodify(cleaned_path, ":p"))

  -- ファイルが存在するか確認
  if vim.fn.filereadable(expanded_path) == 0 then
    return nil, "File not found: " .. expanded_path
  end

  -- 新しいファイル名が指定されていれば追加
  local final_filename
  if new_filename and new_filename ~= "" then
    -- 拡張子がなければ元の拡張子を追加
    if not new_filename:match("%.%w+$") then
      local ext = vim.fn.fnamemodify(expanded_path, ":e")
      new_filename = new_filename .. "." .. ext
    end
    final_filename = new_filename
  else
    final_filename = vim.fn.fnamemodify(expanded_path, ":t")
  end

  -- コマンドを構築して実行
  local escaped_path = vim.fn.shellescape(expanded_path)
  local args = "import --no-color " .. escaped_path
  if new_filename and new_filename ~= "" then
    args = args .. " " .. vim.fn.shellescape(new_filename)
  end

  local output = M.run_cmd(args)
  if not output then
    return nil, "Import failed"
  end

  -- インポートされたファイルのIDを取得
  for _, line in ipairs(output) do
    local note_id = line:match("%[(%d+)%]")
    if note_id then
      return note_id, final_filename
    end
  end
  return nil, "Could not parse import result"
end

-- ノートを削除
function M.delete_note(note_id)
  local output = M.run_cmd("delete --force " .. note_id)
  return output ~= nil
end

-- ノートを別のノートブックに移動
function M.move_note(note_id, dest_notebook)
  local escaped_id = vim.fn.shellescape(note_id)
  local output = M.run_cmd("move --force " .. escaped_id .. " " .. dest_notebook .. ":")
  if not output then
    return nil
  end

  -- 移動後のノートIDを取得
  for _, line in ipairs(output) do
    local new_id = line:match("%[([%w:]+%d+)%]")
    if new_id then
      return new_id
    end
  end
  -- IDが取得できなくても成功とみなす
  return dest_notebook
end

-- ノートブック一覧を取得
function M.list_notebooks()
  -- nbディレクトリ内のサブディレクトリを直接読み取る（より確実）
  local nb_dir = M.get_nb_dir()
  local handle = vim.loop.fs_scandir(nb_dir)
  if not handle then
    return nil
  end

  local notebooks = {}
  while true do
    local name, type = vim.loop.fs_scandir_next(handle)
    if not name then
      break
    end
    -- ディレクトリで、隠しフォルダでないものがノートブック
    if type == "directory" and not name:match("^%.") then
      table.insert(notebooks, name)
    end
  end
  table.sort(notebooks)
  return notebooks
end

-- リスト行をパース（ノートブック情報付き）
-- 例: "[22] タイトル" + notebook="log" -> { full_id = "log:22", notebook = "log", ... }
function M.parse_list_item_with_notebook(line, notebook)
  local note_id = line:match("^%[(.-)%]")
  if not note_id then
    return nil
  end

  local is_image = line:match("🌄") ~= nil
  local is_folder = line:match("📂") ~= nil
  local name

  if is_image then
    name = line:match("%[.-%]%s*🌄%s*(.+)$")
  elseif is_folder then
    name = line:match("%[.-%]%s*📂%s*(.+)$")
  else
    name = line:match("%[.-%]%s*(.+)$")
  end

  if not name then
    return nil
  end

  -- full_id は notebook:note_id 形式で構築
  -- note_id が既に "notebook:id" 形式の場合はそのまま使用
  local full_id
  if note_id:find(":") then
    full_id = note_id
  else
    full_id = notebook .. ":" .. note_id
  end

  return {
    full_id = full_id,
    notebook = notebook,
    name = vim.trim(name),
    is_image = is_image,
    is_folder = is_folder,
    text = line,
  }
end

-- 特定ノートブックのアイテム一覧を取得（フォルダ内を再帰展開）
function M.list_items_for_notebook(notebook, folder_path, depth)
  depth = depth or 0
  if depth > MAX_FOLDER_DEPTH then
    return {}
  end

  local cmd
  if folder_path then
    cmd = notebook .. ":list " .. folder_path .. " --no-color"
  else
    cmd = notebook .. ":list --no-color"
  end

  local output = M.run_cmd(cmd)
  if not output then
    return {}
  end

  local items = {}
  for _, line in ipairs(output) do
    local item = M.parse_list_item_with_notebook(line, notebook)
    if item then
      if folder_path then
        item.folder_path = folder_path
      end
      table.insert(items, item)

      -- フォルダの場合は再帰的に中身を取得
      if item.is_folder then
        local sub_folder = (folder_path or "") .. item.name .. "/"
        local sub_items = M.list_items_for_notebook(notebook, sub_folder, depth + 1)
        for _, sub_item in ipairs(sub_items) do
          table.insert(items, sub_item)
        end
      end
    end
  end
  return items
end

-- 全ノートブックのアイテムを取得
function M.list_all_items()
  local notebooks = M.list_notebooks()
  if not notebooks then
    return nil
  end

  local all_items = {}
  for _, notebook in ipairs(notebooks) do
    local items = M.list_items_for_notebook(notebook)
    for _, item in ipairs(items) do
      table.insert(all_items, item)
    end
  end
  return all_items
end

return M
