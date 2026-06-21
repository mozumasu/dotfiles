#!/usr/bin/env lua

-- コマンドライン引数
local sessions_file = arg[1]
local selected_line = arg[2]

-- 色定義
local PURPLE = '\x1b[38;5;141m'
local BLUE = '\x1b[38;5;117m'
local WHITE = '\x1b[38;5;255m'
local GRAY = '\x1b[38;5;240m'
local GREEN = '\x1b[38;5;114m'
local YELLOW = '\x1b[38;5;214m'
local RESET = '\x1b[0m'

-- pane_idを抽出
local pane_id = selected_line:match("|([^|]+)$")

if not pane_id then
  print("Error: Could not extract pane_id")
  os.exit(1)
end

-- jqでJSONパース
local jq_cmd = string.format(
  "grep '\"pane_id\":\"%s\"' '%s' | jq -r '.workspace,.project,.cwd,.content,.tab_title,.status,.session_id'",
  pane_id,
  sessions_file
)

local handle = io.popen(jq_cmd)
if not handle then
  print("Error: Failed to execute jq")
  os.exit(1)
end

local workspace = handle:read("*line") or ""
local project = handle:read("*line") or ""
local cwd = handle:read("*line") or ""
local content = handle:read("*line") or ""
local tab_title = handle:read("*line") or ""
local status = handle:read("*line") or "idle"
local session_id = handle:read("*line") or ""
handle:close()

-- cwd と sessionId からトランスクリプトファイルのパスを構築
-- 例: /Users/foo/dotfiles → ~/.config/claude/projects/-Users-foo-dotfiles/<sid>.jsonl
local function build_transcript_path(cwd_path, sid)
  if not sid or sid == "" or sid == "null" or not cwd_path or cwd_path == "" then
    return nil
  end
  -- 末尾の "/" を除去（"-Users-...-dotfiles-" のような余分な末尾ハイフンを防ぐ）
  cwd_path = cwd_path:gsub("/+$", "")
  -- 英数字/アンダースコア以外を - に変換
  local encoded = cwd_path:gsub("[^%w]", "-")
  local home = os.getenv("HOME") or ""
  return home .. "/.config/claude/projects/" .. encoded .. "/" .. sid .. ".jsonl"
end

-- トランスクリプトから ai-title と直近 last-prompt を取得
local function read_transcript(transcript_path)
  if not transcript_path then
    return nil, {}
  end
  -- 存在チェック
  local f = io.open(transcript_path, "r")
  if not f then
    return nil, {}
  end
  f:close()

  -- ai-title（最後の1件）
  local title_cmd = string.format(
    [[tail -n 500 '%s' 2>/dev/null | jq -r 'select(.type=="ai-title") | .aiTitle' | tail -n 1]],
    transcript_path
  )
  local th = io.popen(title_cmd)
  local title = nil
  if th then
    title = th:read("*line")
    th:close()
  end

  -- last-prompt（最後の5件、新→旧の順）
  local prompts_cmd = string.format(
    [[tail -n 500 '%s' 2>/dev/null | jq -r 'select(.type=="last-prompt") | .lastPrompt' | awk '!seen[$0]++' | tail -n 5]],
    transcript_path
  )
  local prompts = {}
  local ph = io.popen(prompts_cmd)
  if ph then
    for line in ph:lines() do
      if line and line ~= "" then
        table.insert(prompts, 1, line) -- 新しいものを先頭に
      end
    end
    ph:close()
  end

  return title, prompts
end

-- 改行や制御文字を除去し、長すぎる場合は省略
local function clean_prompt(s, max_len)
  if not s then
    return ""
  end
  s = s:gsub("[\n\r\t]", " ")
  s = s:gsub("%s+", " ")
  s = s:gsub("^%s+", ""):gsub("%s+$", "")
  if max_len and #s > max_len then
    return s:sub(1, max_len) .. "…"
  end
  return s
end

local transcript_path = build_transcript_path(cwd, session_id)
local ai_title, recent_prompts = read_transcript(transcript_path)

-- ヘッダー表示
print(GRAY .. "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" .. RESET)
print(PURPLE .. "🤖 Claude Code Session" .. RESET)
print(GRAY .. "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" .. RESET)
print("")

-- ステータス表示
local status_display
if status == "running" then
  status_display = GREEN .. "● running" .. RESET
elseif status == "waiting" then
  status_display = YELLOW .. "◐ waiting" .. RESET
else
  status_display = GRAY .. "○ idle" .. RESET
end

-- セッション詳細
print(WHITE .. "Status:   " .. RESET .. " " .. status_display)
print(WHITE .. "Workspace:" .. RESET .. " " .. PURPLE .. workspace .. RESET)
print(WHITE .. "Project:  " .. RESET .. " " .. BLUE .. project .. RESET)
print(WHITE .. "Tab:      " .. RESET .. " " .. GRAY .. tab_title .. RESET)
print(WHITE .. "Path:     " .. RESET .. " " .. GRAY .. cwd .. RESET)
print("")

-- AI 生成タイトル（トランスクリプト由来）
if ai_title and ai_title ~= "" and ai_title ~= "null" then
  print(WHITE .. "Title:    " .. RESET .. " " .. BLUE .. clean_prompt(ai_title, 70) .. RESET)
  print("")
elseif content ~= "" and content ~= "null" then
  print(WHITE .. "Session Content:" .. RESET)
  print("  " .. content)
  print("")
end

-- 直近のプロンプト履歴
if #recent_prompts > 0 then
  print(GRAY .. "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" .. RESET)
  print(WHITE .. "Recent Prompts" .. RESET .. GRAY .. " (newest first)" .. RESET)
  print(GRAY .. "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" .. RESET)
  print("")
  for i, p in ipairs(recent_prompts) do
    local cleaned = clean_prompt(p, 70)
    print(string.format("  %s%d.%s %s%s%s", GRAY, i, RESET, WHITE, cleaned, RESET))
  end
  print("")
end

-- 最新出力
print(GRAY .. "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" .. RESET)
print(WHITE .. "Recent Output" .. RESET)
print(GRAY .. "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" .. RESET)
print("")

-- wezterm cliでペイン出力取得
local wezterm_cmd = string.format("wezterm cli get-text --pane-id %s 2>/dev/null | tail -n 20", pane_id)
local wezterm_handle = io.popen(wezterm_cmd)
if wezterm_handle then
  local output = wezterm_handle:read("*all")
  wezterm_handle:close()

  if output and output ~= "" then
    print(output)
  else
    print(GRAY .. "(Could not retrieve pane output)" .. RESET)
  end
else
  print(GRAY .. "(wezterm cli not available)" .. RESET)
end
