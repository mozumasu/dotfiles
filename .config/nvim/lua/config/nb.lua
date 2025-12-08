local M = {}

-- nbのノートディレクトリパスを取得
function M.get_nb_dir()
  return vim.fn.expand("~/src/github.com/mozumasu/nb")
end

-- nbノートのタイトルを取得する関数
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
    -- "# タイトル" 形式からタイトルを抽出
    return first_line:match("^#%s+(.+)")
  end
  return nil
end

-- nbコマンドを実行してノート一覧を取得
function M.list_notes()
  local output = vim.fn.systemlist("NB_EDITOR=: NO_COLOR=1 nb list --no-color")
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return output
end

-- ノートIDからファイルパスを取得
function M.get_note_path(note_id)
  local path = vim.fn.system("NB_EDITOR=: NO_COLOR=1 nb show --path " .. note_id)
  return vim.trim(path)
end

-- ノートを追加して開く
function M.add_note(title)
  local cmd = "NB_EDITOR=: NO_COLOR=1 nb add --no-color"
  local timestamp = os.date("%Y%m%d%H%M%S")
  if title and title ~= "" then
    local escaped_title = title:gsub('"', '\\"')
    cmd = cmd .. ' --filename "' .. timestamp .. '.md" --title "' .. escaped_title .. '"'
  else
    local readable_timestamp = os.date("%Y-%m-%d %H:%M:%S")
    cmd = cmd .. ' --filename "' .. timestamp .. '.md" --title "' .. readable_timestamp .. '"'
  end

  local output = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 then
    return nil
  end

  -- 追加されたノートのIDを取得
  for _, line in ipairs(output) do
    local note_id = line:match("%[(%d+)%]")
    if note_id then
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

  -- 前後の空白とクォートを除去してパスを展開
  local cleaned_path = image_path:gsub("^%s*['\"]?", ""):gsub("['\"]?%s*$", "")
  local expanded_path = vim.fn.expand(cleaned_path)

  -- ファイルが存在するか確認
  if vim.fn.filereadable(expanded_path) == 0 then
    return nil, "File not found: " .. expanded_path
  end

  -- シェルエスケープを使用してコマンドを構築
  local escaped_path = vim.fn.shellescape(expanded_path)
  local cmd = "NB_EDITOR=: NO_COLOR=1 nb import --no-color " .. escaped_path

  -- 新しいファイル名が指定されていれば追加
  local final_filename
  if new_filename and new_filename ~= "" then
    -- 拡張子がなければ元の拡張子を追加
    if not new_filename:match("%.%w+$") then
      local ext = vim.fn.fnamemodify(expanded_path, ":e")
      new_filename = new_filename .. "." .. ext
    end
    cmd = cmd .. " " .. vim.fn.shellescape(new_filename)
    final_filename = new_filename
  else
    final_filename = vim.fn.fnamemodify(expanded_path, ":t")
  end

  local output = vim.fn.systemlist(cmd)

  if vim.v.shell_error ~= 0 then
    return nil, "Import failed"
  end

  -- インポートされたファイル名を取得
  for _, line in ipairs(output) do
    local note_id = line:match("%[(%d+)%]")
    if note_id then
      return note_id, final_filename
    end
  end
  return nil, "Could not parse import result"
end

return M
