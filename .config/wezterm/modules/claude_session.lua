local wezterm = require("wezterm")
local act = wezterm.action
local module = {}

-- アイコン定義
local ICONS = {
  workspace = wezterm.nerdfonts.md_view_dashboard,
  project = wezterm.nerdfonts.md_folder,
  claude = wezterm.nerdfonts.md_robot,
  separator = wezterm.nerdfonts.ple_right_half_circle_thin,
}

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

-- JSON文字列のエスケープ
local function json_escape(str)
  if not str then
    return ""
  end
  str = tostring(str)
  str = str:gsub("\\", "\\\\")
  str = str:gsub('"', '\\"')
  str = str:gsub("\n", "\\n")
  str = str:gsub("\r", "\\r")
  str = str:gsub("\t", "\\t")
  return str
end

-- セッション情報をJSON Lines形式でファイルに出力
local function export_sessions_to_file(sessions, filepath)
  local lines = {}
  for _, session in ipairs(sessions) do
    local project_name = get_project_name(session.cwd)
    local json = string.format(
      '{"pane_id":"%s","workspace":"%s","project":"%s","cwd":"%s","content":"%s","tab_title":"%s"}',
      json_escape(tostring(session.pane_id)),
      json_escape(session.workspace or "default"),
      json_escape(project_name),
      json_escape(session.cwd or ""),
      json_escape(session.content or ""),
      json_escape(session.tab_title or "")
    )
    table.insert(lines, json)
  end

  local file = io.open(filepath, "w")
  if not file then
    wezterm.log_error("Failed to open file for writing: " .. filepath)
    return false
  end

  -- 最後に改行を追加（Bashのreadで最後の行も読み込めるようにする）
  local content = table.concat(lines, "\n") .. "\n"
  file:write(content)
  file:close()

  return true
end

-- セッション情報をfzf用にフォーマット（ANSI色付き）
local function format_session_for_fzf(session)
  local purple = "\x1b[38;5;141m"
  local blue = "\x1b[38;5;117m"
  local white = "\x1b[38;5;255m"
  local gray = "\x1b[38;5;240m"
  local reset = "\x1b[0m"

  local workspace = session.workspace or "default"
  local project_name = get_project_name(session.cwd)
  local content = session.content or ""
  local pane_id = tostring(session.pane_id)

  -- 形式: 🗂 ワークスペース ▸ 📁 プロジェクト ▸ 内容|pane_id
  if content ~= "" then
    return string.format(
      "%s%s %s%s %s%s%s %s%s %s%s %s%s%s %s%s%s|%s",
      purple, ICONS.workspace, workspace, reset,
      gray, ICONS.separator, reset,
      blue, ICONS.project, project_name, reset,
      gray, ICONS.separator, reset,
      white, content, reset,
      pane_id
    )
  else
    return string.format(
      "%s%s %s%s %s%s%s %s%s %s%s|%s",
      purple, ICONS.workspace, workspace, reset,
      gray, ICONS.separator, reset,
      blue, ICONS.project, project_name, reset,
      pane_id
    )
  end
end

-- 全セッションをフォーマットしてファイル出力
local function export_formatted_sessions_to_file(sessions, filepath)
  local lines = {}
  for _, session in ipairs(sessions) do
    table.insert(lines, format_session_for_fzf(session))
  end

  local file = io.open(filepath, "w")
  if not file then
    wezterm.log_error("Failed to open file for writing: " .. filepath)
    return false
  end

  file:write(table.concat(lines, "\n") .. "\n")
  file:close()
  return true
end

-- セッションをアクティブにする
local function activate_session(window, input_pane, sessions, pane_id)
  -- IDを使ってsessions配列からpaneを検索
  for _, session in ipairs(sessions) do
    if tostring(session.pane_id) == pane_id then
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
      wezterm.log_info("Activated pane: " .. pane_id)

      break
    end
  end
end

-- fzfの選択結果を処理
local function process_fzf_result(window, input_pane, sessions, result_file)
  -- 結果ファイルを読み取る
  local file = io.open(result_file, "r")
  if not file then
    wezterm.log_error("Failed to open result file: " .. result_file)
    return
  end

  local line = file:read("*line")
  file:close()

  -- 一時ファイルを削除
  os.remove(result_file)

  -- 空の場合はキャンセルされた
  if not line or line == "" then
    wezterm.log_info("Session selection cancelled")
    return
  end

  -- パイプ区切りからpane_idを抽出
  local pane_id = line:match("|([^|]+)$")
  if not pane_id then
    wezterm.log_error("Failed to extract pane_id from: " .. line)
    return
  end

  wezterm.log_info("Selected pane_id from fzf: " .. pane_id)
  activate_session(window, input_pane, sessions, pane_id)
end

-- fzfを使ったセッションセレクター
local function create_fzf_session_selector()
  return wezterm.action_callback(function(window, pane)
    local sessions = scan_active_claude_sessions()

    if not sessions or #sessions == 0 then
      window:toast_notification("Active Claude Code Sessions", "No active Claude Code sessions found", nil, 4000)
      return
    end

    -- 一時ファイルのパス
    local temp_dir = os.getenv("TMPDIR") or "/tmp"
    local sessions_file = temp_dir .. "/wezterm_claude_sessions_" .. os.time() .. ".jsonl"
    local formatted_file = temp_dir .. "/wezterm_fzf_input_" .. os.time() .. ".txt"
    local result_file = temp_dir .. "/wezterm_claude_result_" .. os.time() .. ".txt"

    -- データをエクスポート
    if not export_sessions_to_file(sessions, sessions_file) then
      window:toast_notification("Active Claude Code Sessions", "Failed to export session data", nil, 4000)
      return
    end

    if not export_formatted_sessions_to_file(sessions, formatted_file) then
      window:toast_notification("Active Claude Code Sessions", "Failed to format session data", nil, 4000)
      os.remove(sessions_file)
      return
    end

    -- スクリプトのパス
    local config_dir = wezterm.config_dir or (os.getenv("HOME") .. "/.config/wezterm")
    local preview_script = config_dir .. "/scripts/preview_claude_session.lua"

    -- Homebrewのパスを環境変数から取得
    local homebrew_prefix = os.getenv("HOMEBREW_PREFIX") or "/opt/homebrew"
    local path_prefix = homebrew_prefix .. "/bin:/usr/local/bin"

    -- fzfカラー設定
    local fzf_colors = "--color=fg:255,bg:-1,hl:117,fg+:255,bg+:237,hl+:141,info:240,prompt:141,pointer:141,marker:141,spinner:141,header:240"

    -- fzfコマンド（PATHを明示的に設定）
    local command = string.format(
      [[fzf \
        --ansi \
        --height=50%% \
        --reverse \
        --border=rounded \
        --prompt="🤖 Claude Code Sessions > " \
        --preview='export PATH=%s:$PATH; lua "%s" "%s" {}' \
        --preview-window=right:60%%:wrap \
        --delimiter='|' \
        --with-nth=1 \
        %s \
        < "%s" \
        > "%s"; exit]],
      path_prefix,
      preview_script,
      sessions_file,
      fzf_colors,
      formatted_file,
      result_file
    )

    -- オーバーレイペインで起動
    local new_pane = pane:split({
      direction = "Bottom",
      size = 1.0,
      args = { os.getenv("SHELL"), "-lc", command },
    })

    window:perform_action(act.TogglePaneZoomState, new_pane)

    -- 結果処理
    wezterm.time.call_after(0.5, function()
      local function check_pane_closed()
        local tab = window:active_tab()
        if not tab then
          return
        end

        local panes = tab:panes()
        local pane_exists = false
        for _, p in ipairs(panes) do
          if p:pane_id() == new_pane:pane_id() then
            pane_exists = true
            break
          end
        end

        if pane_exists then
          wezterm.time.call_after(0.2, check_pane_closed)
        else
          process_fzf_result(window, pane, sessions, result_file)
          os.remove(sessions_file)
          os.remove(formatted_file)
        end
      end

      check_pane_closed()
    end)
  end)
end

-- アクティブセッション用のchoices配列生成
local function create_active_session_choices(sessions)
  local choices = {}

  local purple = "\x1b[38;5;141m" -- ラベンダー（ワークスペース）
  local blue = "\x1b[38;5;117m" -- スカイブルー（プロジェクト）
  local white = "\x1b[38;5;255m" -- ホワイト（セッション内容）
  local gray = "\x1b[38;5;240m" -- ダークグレー（セパレーター）
  local reset = "\x1b[0m" -- リセット

  for _, session in ipairs(sessions) do
    local workspace = session.workspace or "default"
    local project_name = get_project_name(session.cwd)
    local content = session.content or ""

    -- 形式: 🗂 ワークスペース ▸ 📁 プロジェクト名 ▸ セッション内容
    local label
    if content ~= "" then
      label = string.format(
        "%s%s %s%s %s%s %s%s %s%s %s%s %s%s",
        purple,
        ICONS.workspace,
        workspace,
        reset,
        gray,
        ICONS.separator,
        blue,
        ICONS.project,
        project_name,
        reset,
        gray,
        ICONS.separator,
        white,
        content .. reset
      )
    else
      label = string.format(
        "%s%s %s%s %s%s %s%s %s%s",
        purple,
        ICONS.workspace,
        workspace,
        reset,
        gray,
        ICONS.separator,
        blue,
        ICONS.project,
        project_name .. reset
      )
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
      window:toast_notification("Active Claude Code Sessions", "No active Claude Code sessions found", nil, 4000)
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
        title = "🤖 Select Active Claude Code Session",
        choices = choices,
        fuzzy = true,
        fuzzy_description = "Search sessions...",
      }),
      pane
    )
  end)
end

-- configへの適用
function module.apply_to_config(config)
  wezterm.log_info("claude_session module loaded")

  -- LEADER+c: 現在実行中のClaude Codeセッションを検索して切り替え
  -- fzfの可用性チェックは実行時に行われる
  table.insert(config.keys, {
    key = "c",
    mods = "LEADER",
    action = create_fzf_session_selector(),
  })
  wezterm.log_info("claude_session keybinding registered: LEADER+c (active sessions with fzf)")
end

return module
