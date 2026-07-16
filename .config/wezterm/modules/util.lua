local module = {}

-- シェル用のシングルクォートエスケープ
function module.shell_escape(str)
  return "'" .. str:gsub("'", "'\\''") .. "'"
end

-- コマンドを実行し、出力を行ごとの配列で返す（実行失敗時は空配列）
function module.run_lines(cmd)
  local handle = io.popen(cmd)
  if not handle then
    return {}
  end

  local result = handle:read("*a")
  handle:close()

  local lines = {}
  for line in result:gmatch("[^\r\n]+") do
    if line ~= "" then
      table.insert(lines, line)
    end
  end
  return lines
end

return module
