local wezterm = require("wezterm")
local act = wezterm.action
local module = {}

-- プロジェクト名を取得（パスから）
local function get_project_name(path)
  if not path or path == "" then
    return "unknown"
  end
  -- 末尾のスラッシュを削除
  path = path:gsub("/$", "")
  -- 最後のディレクトリ名を取得
  local project_name = path:match("([^/]+)$")
  return project_name or "unknown"
end

-- UTF-8文字列をサニタイズ（不正なバイトを除去）
local function sanitize_utf8(str)
  if not str or str == "" then
    return ""
  end

  local result = {}
  local i = 1
  while i <= #str do
    local success, _ = pcall(utf8.codepoint, str, i)
    if success then
      -- 次の文字の開始位置を取得
      local next_i = utf8.offset(str, 2, i)
      if next_i then
        table.insert(result, str:sub(i, next_i - 1))
        i = next_i
      else
        table.insert(result, str:sub(i))
        break
      end
    else
      -- 不正なバイトをスキップ
      i = i + 1
    end
  end

  return table.concat(result)
end

-- ペインタイトルからセッション内容を取得
local function get_session_content(pane)
  local success, title = pcall(function()
    return pane:get_title()
  end)

  if not success or not title or title == "" then
    return ""
  end

  -- UTF-8をサニタイズ
  title = sanitize_utf8(title)

  if title == "" then
    return ""
  end

  -- 括弧内のテキストを削除（ヘルプテキストなど）
  title = title:gsub("%s*%([^)]+%)%s*", " ")

  -- 前後の空白を削除
  title = title:gsub("^%s+", ""):gsub("%s+$", "")

  -- 長すぎる場合は切り詰める
  local success_width, width = pcall(wezterm.column_width, title)
  if success_width and width > 60 then
    local success_truncate, truncated = pcall(wezterm.truncate_right, title, 60)
    if success_truncate then
      return truncated
    end
  end

  return title
end

-- 現在実行中のClaude Codeセッションをスキャン
local function scan_active_claude_sessions()
  local sessions = {}

  -- 全ウィンドウを走査
  for _, mux_window in ipairs(wezterm.mux.all_windows()) do
    local workspace = mux_window:get_workspace()

    -- 全タブを走査
    for _, tab in ipairs(mux_window:tabs()) do
      local tab_title = tab:get_title()
      local tab_id = tab:tab_id()

      -- 全ペインを走査
      for _, pane_info in ipairs(tab:panes_with_info()) do
        local pane = pane_info.pane

        -- プロセス名をチェック
        local process_name = pane:get_foreground_process_name()
        if process_name and process_name:find("claude") then
          -- 作業ディレクトリを取得
          local cwd_url = pane:get_current_working_dir()
          local cwd = cwd_url and cwd_url.file_path or ""

          -- セッションの内容を取得
          local content = get_session_content(pane)

          table.insert(sessions, {
            pane = pane,
            workspace = workspace,
            tab_title = tab_title,
            cwd = cwd,
            content = content,
            pane_id = pane:pane_id(),
            mux_window = mux_window,
            tab = tab,
            tab_id = tab_id,
          })
        end
      end
    end
  end

  return sessions
end

-- アクティブセッション用のchoices配列生成
local function create_active_session_choices(sessions)
  local choices = {}

  for _, session in ipairs(sessions) do
    local workspace = session.workspace or "default"
    local project_name = get_project_name(session.cwd)
    local content = session.content or ""

    -- 表示形式: [ワークスペース] プロジェクト名 | セッション内容
    local label
    if content ~= "" then
      label = string.format("[%s] %s | %s", workspace, project_name, content)
    else
      label = string.format("[%s] %s", workspace, project_name)
    end

    table.insert(choices, {
      label = label,
      id = tostring(session.pane_id),
    })
  end

  return choices
end

-- アクティブセッションセレクター
local function create_active_session_selector()
  return wezterm.action_callback(function(window, pane)
    local sessions = scan_active_claude_sessions()

    if not sessions or #sessions == 0 then
      window:toast_notification(
        "Active Claude Code Sessions",
        "No active Claude Code sessions found",
        nil,
        4000
      )
      return
    end

    local choices = create_active_session_choices(sessions)

    window:perform_action(
      act.InputSelector({
        action = wezterm.action_callback(function(_, input_pane, id, label)
          if not id and not label then
            wezterm.log_info("Active session selection cancelled")
            return
          end

          wezterm.log_info("Selected active Claude Code session: " .. (label or ""))

          -- IDを使ってsessions配列からpaneを検索
          for _, session in ipairs(sessions) do
            if tostring(session.pane_id) == id then
              local target_pane = session.pane
              local target_workspace = session.workspace
              local current_workspace = wezterm.mux.get_active_workspace()

              if not target_pane then
                wezterm.log_error("Failed to activate pane: pane not found")
                window:toast_notification(
                  "Active Claude Code Sessions",
                  "Failed to activate session: pane not found",
                  nil,
                  4000
                )
                return
              end

              -- 別のワークスペースの場合は切り替え
              if target_workspace ~= current_workspace then
                wezterm.log_info("Switching workspace: " .. current_workspace .. " -> " .. target_workspace)
                window:perform_action(act.SwitchToWorkspace({ name = target_workspace }), input_pane)
              end

              -- タブのインデックスを取得してアクティブにする
              local mux_window = session.mux_window
              if mux_window then
                local tabs = mux_window:tabs()
                local tab_index = nil
                for i, tab in ipairs(tabs) do
                  if tab:tab_id() == session.tab_id then
                    tab_index = i - 1 -- 0-indexed
                    break
                  end
                end

                if tab_index then
                  window:perform_action(act.ActivateTab(tab_index), input_pane)
                  wezterm.log_info("Activated tab index: " .. tab_index)
                end
              end

              -- ペインをアクティブにする
              target_pane:activate()
              wezterm.log_info("Activated pane: " .. id)

              break
            end
          end
        end),
        title = "Select Active Claude Code Session",
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
  -- LEADER+c: 現在実行中のClaude Codeセッションを検索して切り替え
  table.insert(config.keys, {
    key = "c",
    mods = "LEADER",
    action = create_active_session_selector(),
  })
  wezterm.log_info("claude_session keybinding registered: LEADER+c (active sessions)")
end

return module
