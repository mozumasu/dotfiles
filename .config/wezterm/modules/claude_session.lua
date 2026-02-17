local wezterm = require("wezterm")
local act = wezterm.action
local module = {}

local HISTORY_FILE = wezterm.home_dir .. "/.config/claude/history.jsonl"

-- セッション履歴の読み込み
local function load_claude_sessions()
  local file = io.open(HISTORY_FILE, "r")
  if not file then
    return nil
  end

  local sessions = {}
  for line in file:lines() do
    if line ~= "" then
      local success, parsed = pcall(wezterm.json_parse, line)
      if success and parsed then
        table.insert(sessions, parsed)
      else
        wezterm.log_warn("Failed to parse JSON line: " .. line)
      end
    end
  end
  file:close()

  if #sessions == 0 then
    return nil
  end

  -- timestampで降順ソート（最新が先頭）
  table.sort(sessions, function(a, b)
    return (a.timestamp or "") > (b.timestamp or "")
  end)

  return sessions
end

-- プロジェクトごとに最新のセッションのみ抽出
local function deduplicate_sessions(sessions)
  local seen_projects = {}
  local unique_sessions = {}

  for _, session in ipairs(sessions) do
    local project_path = session.project or ""
    if project_path ~= "" and not seen_projects[project_path] then
      seen_projects[project_path] = true
      table.insert(unique_sessions, session)
    end
  end

  return unique_sessions
end

-- プロジェクト名を取得（パスから）
local function get_project_name(project_path)
  return project_path:match("([^/]+)/?$") or project_path
end

-- ユーザー入力を60文字に制限（UTF-8対応）
local function truncate_text(text, max_length)
  if not text or text == "" then
    return "(no description)"
  end

  -- 改行を削除してスペースに置換
  text = text:gsub("\n", " "):gsub("\r", "")

  if #text <= max_length then
    return text
  end

  -- UTF-8文字単位で切り取る
  local truncated = ""
  local byte_count = 0

  for _, code in utf8.codes(text) do
    local char = utf8.char(code)
    if byte_count + #char > max_length then
      break
    end
    truncated = truncated .. char
    byte_count = byte_count + #char
  end

  return truncated .. "..."
end

-- タイムスタンプをフォーマット (YYYY-MM-DD HH:MM)
local function format_timestamp(timestamp)
  if not timestamp then
    return ""
  end

  -- UNIX timestamp (milliseconds) を日時文字列に変換
  -- timestampはミリ秒単位なので秒に変換
  local seconds = math.floor(timestamp / 1000)
  local date_str = os.date("%Y-%m-%d %H:%M", seconds)

  return date_str or ""
end

-- InputSelector用のchoices配列生成
local function create_session_choices(sessions)
  local choices = {}

  for _, session in ipairs(sessions) do
    local project_name = get_project_name(session.project or "")
    local user_input = truncate_text(session.display, 60)
    local timestamp = format_timestamp(session.timestamp)

    local label = string.format("%s | %s | %s", project_name, user_input, timestamp)

    table.insert(choices, {
      label = label,
      id = wezterm.json_encode({
        sessionId = session.sessionId,
        project = session.project,
      }),
    })
  end

  return choices
end

-- InputSelectorアクション生成
local function create_session_selector()
  return wezterm.action_callback(function(window, pane)
    local sessions = load_claude_sessions()

    if not sessions or #sessions == 0 then
      window:toast_notification(
        "Claude Code Session Selector",
        "No Claude Code session history found. Please check " .. HISTORY_FILE,
        nil,
        4000
      )
      return
    end

    -- プロジェクトごとに最新のセッションのみ抽出
    local unique_sessions = deduplicate_sessions(sessions)

    if #unique_sessions == 0 then
      window:toast_notification("Claude Code Session Selector", "No valid sessions found", nil, 4000)
      return
    end

    local choices = create_session_choices(unique_sessions)

    window:perform_action(
      act.InputSelector({
        action = wezterm.action_callback(function(_, input_pane, id, label)
          if not id and not label then
            wezterm.log_info("Claude Code session selection cancelled")
            return
          end

          wezterm.log_info("Selected Claude Code session: " .. (label or ""))

          -- IDからsessionIdとprojectを取得
          local success, data = pcall(wezterm.json_parse, id)
          if not success or not data then
            wezterm.log_error("Failed to parse session data")
            return
          end

          local session_id = data.sessionId
          local project = data.project

          if not session_id or not project then
            wezterm.log_error("Invalid session data")
            return
          end

          -- cd <project> && claude code --resume <session_id>
          local command = string.format('cd "%s" && claude code --resume %s', project, session_id)

          -- 新しいペインを作成してコマンド実行
          local new_pane = input_pane:split({
            direction = "Bottom",
            size = 1.0,
            args = { os.getenv("SHELL"), "-lc", command },
          })

          -- フルスクリーン化
          window:perform_action(act.TogglePaneZoomState, new_pane)
        end),
        title = "Select Claude Code Session",
        choices = choices,
        fuzzy = true,
      }),
      pane
    )
  end)
end

-- configへの適用
function module.apply_to_config(config)
  wezterm.log_info("claude_session module loaded")
  table.insert(config.keys, {
    key = "c",
    mods = "LEADER",
    action = create_session_selector(),
  })
  wezterm.log_info("claude_session keybinding registered: LEADER+c")
end

return module
