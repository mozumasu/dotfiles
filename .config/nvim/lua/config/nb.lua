local M = {}

-- nbコマンドのプレフィックス（TERM=dumbでANSIエスケープを完全無効化）
local NB_CMD = "TERM=dumb NB_EDITOR=: NO_COLOR=1 nb"

-- フォルダ再帰展開の最大深度（無限再帰防止）
local MAX_FOLDER_DEPTH = 5

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

-- 指定 notebook の git に変更をコミット（バックグラウンド非同期）
local function git_commit_async(notebook_dir, filename, message)
  if not vim.uv.fs_stat(notebook_dir .. "/.git") then
    return
  end
  vim.system({ "git", "-C", notebook_dir, "add", filename }, { text = true }, function(add_result)
    if add_result.code == 0 then
      vim.system({ "git", "-C", notebook_dir, "commit", "-m", message }, { text = true })
    end
  end)
end

-- nbのノートディレクトリパスを取得
function M.get_nb_dir()
  -- nbのディレクトリパスに合わせて変更してください
  return vim.fn.expand("~/src/github.com/mozumasu/nb")
end

-- Claude Code の plansDirectory（claude-code.nix で `./plans` を設定）
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
        title = read_md_title(path) or name,
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

-- 任意のファイルを nb 配下の notebook へ移動
-- title を渡すとファイル名は <timestamp>.md、H1 をその title に書き換える
-- title が nil なら元ファイル名を維持
-- 戻り値: 新パス、エラーメッセージ
function M.adopt_file(src_path, dest_notebook, title)
  if not src_path or src_path == "" then
    return nil, "No source path"
  end
  if not dest_notebook or dest_notebook == "" then
    return nil, "Notebook required"
  end
  if not vim.uv.fs_stat(src_path) then
    return nil, "Source not found: " .. src_path
  end

  local nb_dir = M.get_nb_dir()
  local notebook_dir = nb_dir .. "/" .. dest_notebook
  if not vim.uv.fs_stat(notebook_dir) then
    return nil, "Notebook not found: " .. dest_notebook
  end

  local filename
  if title and title ~= "" then
    filename = os.date("%Y%m%d%H%M%S") .. ".md"
  else
    filename = vim.fn.fnamemodify(src_path, ":t")
  end

  local dst_path = notebook_dir .. "/" .. filename
  -- 衝突回避
  if vim.uv.fs_stat(dst_path) then
    local stem, ext = filename:match("^(.+)(%.[^.]+)$")
    if not stem then
      stem, ext = filename, ""
    end
    local i = 1
    while vim.uv.fs_stat(dst_path) do
      filename = string.format("%s-%d%s", stem, i, ext)
      dst_path = notebook_dir .. "/" .. filename
      i = i + 1
    end
  end

  -- title 指定時は H1 を差し替え
  if title and title ~= "" then
    local lines = {}
    local f = io.open(src_path, "r")
    if not f then
      return nil, "Cannot read source"
    end
    for line in f:lines() do
      table.insert(lines, line)
    end
    f:close()
    if lines[1] and lines[1]:match("^#%s+") then
      lines[1] = "# " .. title
    else
      table.insert(lines, 1, "# " .. title)
    end
    local out = io.open(dst_path, "w")
    if not out then
      return nil, "Cannot write destination"
    end
    out:write(table.concat(lines, "\n") .. "\n")
    out:close()
    vim.uv.fs_unlink(src_path)
  else
    if not vim.uv.fs_rename(src_path, dst_path) then
      return nil, "Rename failed"
    end
  end

  git_commit_async(notebook_dir, filename, "Adopt: " .. filename)
  return dst_path
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

-- nbノートのタイトルを取得する関数（bufferline用、H1 / frontmatter 両対応）
function M.get_title(filepath)
  local nb_dir = M.get_nb_dir()
  if not filepath:match("^" .. vim.pesc(nb_dir)) then
    return nil
  end
  return read_md_title(filepath)
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

-- ノートを追加して作成されたファイルパスを返す
-- ファイル作成は同期（即座にエディタで開けるよう）、git add/commit はバックグラウンド非同期
function M.add_note(title, notebook)
  if not notebook then
    return nil
  end
  local timestamp = os.date("%Y%m%d%H%M%S")
  local note_title = (title and title ~= "") and title or os.date("%Y-%m-%d %H:%M:%S")
  local filename = timestamp .. ".md"
  local nb_dir = M.get_nb_dir()
  local notebook_dir = nb_dir .. "/" .. notebook
  local path = notebook_dir .. "/" .. filename

  -- 同期: ファイル作成
  local f = io.open(path, "w")
  if not f then
    return nil
  end
  f:write("# " .. note_title .. "\n")
  f:close()

  git_commit_async(notebook_dir, filename, "Add: " .. note_title)
  return path
end

-- 画像（など）をnotebookにインポートする
-- ファイルコピーは同期、git commit はバックグラウンド非同期
-- 戻り値: (final_filename, err)
function M.import_image(image_path, notebook, new_filename)
  if not image_path or image_path == "" then
    return nil, "No path provided"
  end
  if not notebook then
    return nil, "Notebook required"
  end

  -- パスをクリーンアップ: 空白/改行/クォート除去、エスケープされたスペースを復元
  local cleaned_path = image_path
    :gsub("^[%s\n]*['\"]?", "")
    :gsub("['\"]?[%s\n]*$", "")
    :gsub("/ ([^/])", " %1") -- Vim補完で「\ 」が「/ 」に変換される問題を修正
    :gsub("\\ ", " ")

  local expanded_path = vim.fn.resolve(vim.fn.fnamemodify(cleaned_path, ":p"))

  if vim.fn.filereadable(expanded_path) == 0 then
    return nil, "File not found: " .. expanded_path
  end

  -- 最終ファイル名の決定（新ファイル名指定がなければ元の basename）
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

  local notebook_dir = M.get_nb_dir() .. "/" .. notebook
  local dst_path = notebook_dir .. "/" .. final_filename

  -- 同名衝突時は -1, -2... を付与
  if vim.uv.fs_stat(dst_path) then
    local stem, ext = final_filename:match("^(.+)(%.[^.]+)$")
    if not stem then
      stem, ext = final_filename, ""
    end
    local i = 1
    while vim.uv.fs_stat(dst_path) do
      final_filename = string.format("%s-%d%s", stem, i, ext)
      dst_path = notebook_dir .. "/" .. final_filename
      i = i + 1
    end
  end

  local ok, err = vim.uv.fs_copyfile(expanded_path, dst_path)
  if not ok then
    return nil, "Copy failed: " .. (err or "unknown")
  end

  git_commit_async(notebook_dir, final_filename, "Import: " .. final_filename)

  return final_filename
end

-- ノートを削除（note_id は "notebook:filename" 形式）
-- ファイル削除は同期、git commit はバックグラウンド非同期
function M.delete_note(note_id)
  local notebook, filename = note_id:match("^([^:]+):(.+)$")
  if not notebook or not filename then
    return false
  end
  local notebook_dir = M.get_nb_dir() .. "/" .. notebook
  local path = notebook_dir .. "/" .. filename

  if not vim.uv.fs_unlink(path) then
    return false
  end

  git_commit_async(notebook_dir, filename, "Delete: " .. filename)
  return true
end

-- ノートを別のノートブックに移動（note_id は "src_notebook:filename" 形式）
-- ファイル rename は同期、両 repo の git commit はバックグラウンド非同期
function M.move_note(note_id, dest_notebook)
  local src_notebook, filename = note_id:match("^([^:]+):(.+)$")
  if not src_notebook or not filename or not dest_notebook then
    return nil
  end
  local nb_dir = M.get_nb_dir()
  local src_dir = nb_dir .. "/" .. src_notebook
  local dst_dir = nb_dir .. "/" .. dest_notebook

  if not vim.uv.fs_rename(src_dir .. "/" .. filename, dst_dir .. "/" .. filename) then
    return nil
  end

  git_commit_async(src_dir, filename, "Move out: " .. filename)
  git_commit_async(dst_dir, filename, "Move in: " .. filename)

  return dest_notebook .. ":" .. filename
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
        local stat = vim.uv.fs_stat(entry_path)
        table.insert(items, {
          notebook = notebook,
          name = title,
          filename = name,
          is_image = is_image_file(name),
          is_folder = false,
          file = entry_path,
          folder_path = fp,
          full_id = notebook .. ":" .. name,
          mtime = stat and stat.mtime.sec or 0,
          -- snacks picker の matcher が参照する検索用文字列
          text = string.format("[%s] %s%s", notebook, fp or "", title),
        })
      end
    end
  end
end

-- 全ノートブックのアイテムをファイルシステムから直接取得（高速）
-- 結果は mtime 降順（最近編集したノートが上）
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
  table.sort(all_items, function(a, b)
    return a.mtime > b.mtime
  end)
  return all_items
end

return M
