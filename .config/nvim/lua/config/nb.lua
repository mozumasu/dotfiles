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

-- ノートを削除（note_id は "notebook:id" / "notebook:filename" / "id" のいずれも可）
function M.delete_note(note_id)
  local output = M.run_cmd("delete --force " .. vim.fn.shellescape(note_id))
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

-- 画像拡張子の判定
local IMAGE_EXTS = {
  jpg = true,
  jpeg = true,
  png = true,
  gif = true,
  webp = true,
  svg = true,
  bmp = true,
  heic = true,
}

local function is_image_file(name)
  local ext = name:match("%.([^.]+)$")
  return ext ~= nil and IMAGE_EXTS[ext:lower()] == true
end

-- markdown ファイルから表示用タイトルを取得（H1 / frontmatter 両対応）
local function read_md_title(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local first = f:read("*l")
  if not first then
    f:close()
    return nil
  end

  -- 1 行目が H1 の最頻出ケース
  local h1 = first:match("^#%s+(.+)")
  if h1 then
    f:close()
    return h1
  end

  -- frontmatter 形式
  if first == "---" then
    for _ = 1, 30 do
      local line = f:read("*l")
      if not line or line == "---" then
        break
      end
      local t = line:match('^title:%s*"(.-)"%s*$')
        or line:match("^title:%s*'(.-)'%s*$")
        or line:match("^title:%s*(.-)%s*$")
      if t and t ~= "" then
        f:close()
        return t
      end
    end
    -- frontmatter の後ろに H1 があれば採用
    for _ = 1, 30 do
      local line = f:read("*l")
      if not line then
        break
      end
      local h1_after = line:match("^#%s+(.+)")
      if h1_after then
        f:close()
        return h1_after
      end
    end
  end

  f:close()
  return nil
end

-- ノートブック配下を再帰的に walk してアイテムを items に積む
local function walk_notebook(dir, notebook, folder_path, depth, items)
  if depth > MAX_FOLDER_DEPTH then
    return
  end
  local handle = vim.uv.fs_scandir(dir)
  if not handle then
    return
  end

  while true do
    local name, type = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end
    if name:sub(1, 1) ~= "." then
      local entry_path = dir .. "/" .. name
      if type == "directory" then
        walk_notebook(entry_path, notebook, folder_path .. name .. "/", depth + 1, items)
      elseif type == "file" then
        local title = name
        if name:match("%.md$") then
          title = read_md_title(entry_path) or name
        end
        local fp = folder_path ~= "" and folder_path or nil
        table.insert(items, {
          notebook = notebook,
          name = title,
          filename = name,
          is_image = is_image_file(name),
          is_folder = false,
          file = entry_path,
          folder_path = fp,
          full_id = notebook .. ":" .. name,
          -- snacks picker の matcher が参照する検索用文字列
          text = string.format("[%s] %s%s", notebook, fp or "", title),
        })
      end
    end
  end
end

-- 全ノートブックのアイテムをファイルシステムから直接取得（高速）
function M.list_all_items()
  local nb_dir = M.get_nb_dir()
  local notebooks = M.list_notebooks()
  if not notebooks then
    return nil
  end

  local all_items = {}
  for _, notebook in ipairs(notebooks) do
    walk_notebook(nb_dir .. "/" .. notebook, notebook, "", 0, all_items)
  end
  return all_items
end

return M
