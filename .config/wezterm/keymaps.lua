local wezterm = require("wezterm")
local act = wezterm.action

local module = {}

-- オーバーレイペインでコマンドを実行するヘルパー関数（autoload関数用: -lic で .zshrc を読み込む）
local function spawn_overlay_pane_interactive(command)
  return wezterm.action_callback(function(window, pane)
    local new_pane = pane:split({
      direction = "Bottom",
      size = 1.0,
      args = { os.getenv("SHELL"), "-lic", command },
    })
    window:perform_action(act.TogglePaneZoomState, new_pane)
  end)
end

-- オーバーレイペインでコマンドを実行するヘルパー関数
local function spawn_overlay_pane(command)
  return wezterm.action_callback(function(window, pane)
    local new_pane = pane:split({
      direction = "Bottom",
      size = 1.0,
      args = { os.getenv("SHELL"), "-lc", command },
    })
    window:perform_action(act.TogglePaneZoomState, new_pane)
  end)
end

-- ペインの高さを指定したパーセンテージに設定する内部処理
local function apply_pane_height_percent(window, pane, percent)
  local tab = pane:tab()
  local tab_size = tab:get_size()
  local pane_dims = pane:get_dimensions()
  local pane_id = pane:pane_id()

  -- ペインの位置を取得（topが0なら上のペイン）
  local is_top_pane = false
  for _, info in ipairs(tab:panes_with_info()) do
    if info.pane:pane_id() == pane_id then
      is_top_pane = (info.top == 0)
      break
    end
  end

  local target_rows = math.floor(tab_size.rows * percent)
  local current_rows = pane_dims.viewport_rows
  local diff = current_rows - target_rows

  if is_top_pane then
    -- 上ペイン: 縮小はUp、拡大はDown
    if diff > 0 then
      window:perform_action(act.AdjustPaneSize({ "Up", diff }), pane)
    elseif diff < 0 then
      window:perform_action(act.AdjustPaneSize({ "Down", -diff }), pane)
    end
  else
    -- 下ペイン: 縮小はDown、拡大はUp
    if diff > 0 then
      window:perform_action(act.AdjustPaneSize({ "Down", diff }), pane)
    elseif diff < 0 then
      window:perform_action(act.AdjustPaneSize({ "Up", -diff }), pane)
    end
  end
end

local function set_pane_height_percent(percent)
  return wezterm.action_callback(function(window, pane)
    apply_pane_height_percent(window, pane, percent)
  end)
end

-- ペインの幅を指定したパーセンテージに設定するヘルパー関数
local function set_pane_width_percent(percent)
  return wezterm.action_callback(function(window, pane)
    local tab = pane:tab()
    local tab_size = tab:get_size()
    local pane_dims = pane:get_dimensions()
    local pane_id = pane:pane_id()

    -- ペインの位置を取得（leftが0なら左のペイン）
    local is_left_pane = false
    for _, info in ipairs(tab:panes_with_info()) do
      if info.pane:pane_id() == pane_id then
        is_left_pane = (info.left == 0)
        break
      end
    end

    local target_cols = math.floor(tab_size.cols * percent)
    local current_cols = pane_dims.cols
    local diff = current_cols - target_cols

    if is_left_pane then
      -- 左ペイン: 縮小はLeft、拡大はRight
      if diff > 0 then
        window:perform_action(act.AdjustPaneSize({ "Left", diff }), pane)
      elseif diff < 0 then
        window:perform_action(act.AdjustPaneSize({ "Right", -diff }), pane)
      end
    else
      -- 右ペイン: 縮小はRight、拡大はLeft
      if diff > 0 then
        window:perform_action(act.AdjustPaneSize({ "Right", diff }), pane)
      elseif diff < 0 then
        window:perform_action(act.AdjustPaneSize({ "Left", -diff }), pane)
      end
    end
  end)
end

-- ペインの最小化前の高さを記憶するテーブル (pane_id -> percent)
local pane_height_store = {}

local leader = { key = "q", mods = "CTRL", timeout_milliseconds = 2000 }

local keys = {
  -- AltキーをMetaキーとして扱いつつ、バックスラッシュ機能（Alt+¥）は維持する
  { key = "¥", mods = "ALT", action = wezterm.action.SendString("\\") },
  -- 終了
  -- { key = "q", mods = "SUPER", action = act.QuitApplication },
  -- ウィンドウ操作
  { key = "Enter", mods = "ALT", action = act.ToggleFullScreen },
  { key = "n", mods = "SUPER", action = act.SpawnWindow },
  -- タブ操作
  { key = "Tab", mods = "CTRL", action = act.ActivateTabRelative(1) },
  { key = "Tab", mods = "SHIFT|CTRL", action = act.ActivateTabRelative(-1) },
  { key = "1", mods = "SUPER", action = act.ActivateTab(0) },
  { key = "2", mods = "SUPER", action = act.ActivateTab(1) },
  { key = "3", mods = "SUPER", action = act.ActivateTab(2) },
  { key = "4", mods = "SUPER", action = act.ActivateTab(3) },
  { key = "5", mods = "SUPER", action = act.ActivateTab(4) },
  { key = "6", mods = "SUPER", action = act.ActivateTab(5) },
  { key = "7", mods = "SUPER", action = act.ActivateTab(6) },
  { key = "8", mods = "SUPER", action = act.ActivateTab(7) },
  { key = "9", mods = "SUPER", action = act.ActivateTab(-1) },
  { key = "t", mods = "SUPER", action = act.SpawnTab("CurrentPaneDomain") },
  { key = "w", mods = "SUPER", action = act.CloseCurrentTab({ confirm = true }) },
  -- Pane操作
  -- <C-h> has been remapped to Backspace, so Backspace must be specified here
  { key = "Backspace", mods = "SHIFT", action = act.ActivatePaneDirection("Left") },
  { key = "l", mods = "SHIFT|CTRL", action = act.ActivatePaneDirection("Right") },
  { key = "k", mods = "SHIFT|CTRL", action = act.ActivatePaneDirection("Up") },
  { key = "j", mods = "SHIFT|CTRL", action = act.ActivatePaneDirection("Down") },

  -- フォントサイズ変更
  { key = "+", mods = "SUPER", action = act.IncreaseFontSize },
  { key = "-", mods = "SUPER", action = act.DecreaseFontSize },
  { key = "0", mods = "SUPER", action = act.ResetFontSize },

  { key = "c", mods = "SUPER", action = act.CopyTo("Clipboard") },
  { key = "v", mods = "SUPER", action = act.PasteFrom("Clipboard") },

  -- Debug
  { key = "l", mods = "SUPER", action = act.ShowDebugOverlay },
  { key = "R", mods = "CTRL", action = act.ReloadConfiguration },
  { key = "r", mods = "SUPER", action = act.ReloadConfiguration },
  -- { key = "L", mods = "CTRL", action = act.ShowDebugOverlay },

  -- コマンドパレット
  { key = "P", mods = "CTRL", action = act.ActivateCommandPalette },
  -- 文字選択パレット
  {
    key = "U",
    mods = "CTRL",
    action = act.CharSelect({ copy_on_select = true, copy_to = "ClipboardAndPrimarySelection" }),
  },

  -- モード切替
  -- アクティブペインのズーム切替（ペインが2つ以上の場合のみ）
  {
    key = "Z",
    mods = "CTRL",
    action = wezterm.action_callback(function(window, pane)
      local tab = pane:tab()
      if #tab:panes() > 1 then
        window:perform_action(act.TogglePaneZoomState, pane)
      end
    end),
  },

  -- 誤爆するので非有効にしがち
  -- { key = "k", mods = "SUPER", action = act.ClearScrollback("ScrollbackOnly") },
  -- { key = "m", mods = "SUPER", action = act.Hide },
  -- { key = "H", mods = "CTRL", action = act.HideApplication },

  -- control + space がMaccOSのIME切り替えに使われるので、別のキーに割り当て
  -- { key = "phys:Space", mods = "SHIFT|CTRL", action = act.QuickSelect },
  { key = " ", mods = "SUPER", action = act.QuickSelect },

  -- スクロール
  { key = "PageUp", mods = "SHIFT", action = act.ScrollByPage(-1) },
  { key = "PageDown", mods = "SHIFT", action = act.ScrollByPage(1) },
  { key = "p", mods = "ALT|CTRL", action = act.ScrollByPage(-0.5) },
  { key = "n", mods = "ALT|CTRL", action = act.ScrollByPage(0.5) },

  -- コピー・ペースト
  { key = "Copy", mods = "NONE", action = act.CopyTo("Clipboard") },
  { key = "Paste", mods = "NONE", action = act.PasteFrom("Clipboard") },

  -- Claude Codeで改行できるようにする
  { key = "Enter", mods = "SHIFT", action = wezterm.action.SendString("\n") },

  -- ScrollToPrompt
  { key = "[", mods = "ALT", action = act.ScrollToPrompt(-1) },
  { key = "]", mods = "ALT", action = act.ScrollToPrompt(1) },

  -- Tab rename (tmux: prefix + ,)
  {
    key = ",",
    mods = "LEADER",
    action = wezterm.action_callback(function(window, pane)
      local tab = pane:tab()
      local tab_id = tab:tab_id()
      local tab_module = require("tab")
      local current = tab_module.custom_title[tab_id] or ""
      window:perform_action(
        act.PromptInputLine({
          description = "(wezterm) Rename tab (empty to reset):",
          initial_value = current,
          action = wezterm.action_callback(function(_, inner_pane, line)
            if line == nil then return end
            local t = inner_pane:tab()
            if line == "" then
              tab_module.custom_title[t:tab_id()] = nil
            else
              tab_module.custom_title[t:tab_id()] = line
            end
          end),
        }),
        pane
      )
    end),
  },

  -- Pane
  { key = ":", mods = "CTRL", action = act.PaneSelect },
  { key = "r", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) }, -- Control+q → r 横分割
  { key = "d", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) }, -- Control+q → d 縦分割
  { key = "x", mods = "LEADER", action = act({ CloseCurrentPane = { confirm = true } }) }, -- Control+q → x ペインを閉じる
  -- Ctrl+Shift+C: 現在のペインを最大化（他ペインを1行に最小化）
  -- { key = "C", mods = "CTRL|SHIFT", action = set_pane_height_percent(0) },

  -- Ctrl+Shift+C: すでに1行に最小化されていれば元の高さ（or 50%）に復元、そうでなければ1行に最小化してラベルを注入
  {
    key = "c",
    mods = "CTRL|SHIFT",
    action = wezterm.action_callback(function(window, pane)
      local pane_dims = pane:get_dimensions()
      local pane_id = pane:pane_id()

      -- すでに1行に最小化されている場合は元の高さ（記憶がなければ50%）に復元
      if pane_dims.viewport_rows <= 1 then
        local restore_percent = pane_height_store[pane_id] or 0.5
        pane_height_store[pane_id] = nil
        apply_pane_height_percent(window, pane, restore_percent)
        return
      end

      -- 最小化前に現在の高さ比率を保存
      local tab = pane:tab()
      local tab_size = tab:get_size()
      pane_height_store[pane_id] = pane_dims.viewport_rows / tab_size.rows

      local title = pane:get_title()
      local cwd_uri = pane:get_current_working_dir()
      local cwd = cwd_uri and cwd_uri.file_path:match("([^/]+)/?$") or ""
      -- titleがcwdと同じ場合はプロセス名にフォールバック
      local name
      if title ~= "" and title ~= cwd then
        name = title
      else
        local process = pane:get_foreground_process_name()
        name = process and process:match("([^/]+)$") or "?"
      end
      local label = cwd ~= "" and (name .. " (" .. cwd .. ")") or name
      apply_pane_height_percent(window, pane, 0) -- 現在のペインを1行に最小化
      -- リサイズ完了後にラベルを注入
      wezterm.time.call_after(0.05, function()
        pane:inject_output("\r\x1b[2K\x1b[33m◀ " .. label .. " ▶\x1b[0m")
      end)
    end),
  },

  -- AWS ARN を Quick Select してブラウザで開く
  {
    key = "a",
    mods = "LEADER",
    action = wezterm.action.QuickSelectArgs({
      label = "open aws console",
      patterns = {
        -- ARNパターン: arn:partition:service:region:account-id:resource
        "\\barn:[\\w\\-]+:[\\w\\-]+:[\\w\\-]*:[0-9]*:[\\w\\-/:=.]+",
      },
      action = wezterm.action_callback(function(window, pane)
        local arn = window:get_selection_text_for_pane(pane)
        wezterm.log_info("opening AWS console for: " .. arn)
        wezterm.open_with("https://console.aws.amazon.com/go/view?arn=" .. arn)
      end),
    }),
  },

  -- Search mode
  {
    key = "f",
    mods = "SUPER",
    action = act.Multiple({
      act.Search("CurrentSelectionOrEmptyString"),
      act.CopyMode("ClearPattern"),
      act.CopyMode("ClearSelectionMode"),
    }),
  },
  {
    key = "X",
    mods = "CTRL",
    action = act.Multiple({
      act.ActivateCopyMode,
      act.CopyMode("ClearPattern"),
      act.CopyMode("ClearSelectionMode"),
      act.CopyMode("MoveToViewportMiddle"),
    }),
  },
  { key = "s", mods = "LEADER", action = act.ActivateKeyTable({ name = "setting_mode", one_shot = false }) },

  -- Codex stash: Ctrl+G を送信 → Neovim が開いたら <leader>S でスタッシュ → :wq で戻る
  {
    key = "u",
    mods = "LEADER",
    action = wezterm.action_callback(function(window, pane)
      -- Ctrl+G を送信して Codex に Neovim を開かせる
      window:perform_action(wezterm.action.SendKey({ key = "g", mods = "CTRL" }), pane)
      -- Neovim が起動するまで待つ（500ms）
      wezterm.time.call_after(0.5, function()
        -- <Space>S でスタッシュ（LazyVim のデフォルト leader = Space）
        window:perform_action(wezterm.action.SendString(" S"), pane)
        -- スタッシュ処理完了を待つ（300ms）
        wezterm.time.call_after(0.3, function()
          -- :wq で保存・終了
          window:perform_action(wezterm.action.SendString(":wq\n"), pane)
          window:set_right_status("📦 Stashed!")
          wezterm.time.call_after(3, function()
            window:set_right_status("")
          end)
        end)
      end)
    end),
  },

  -- Codex stash pop: スタッシュファイルからポップしてペーストする
  {
    key = "y",
    mods = "LEADER",
    action = wezterm.action_callback(function(window, pane)
      local stash_file = os.getenv("HOME") .. "/.local/share/codex_stash.txt"
      local f = io.open(stash_file, "r")
      if not f then
        window:set_right_status("⚠ Stash empty")
        wezterm.time.call_after(3, function()
          window:set_right_status("")
        end)
        return
      end
      local content = f:read("*a")
      f:close()
      if content == "" then
        window:set_right_status("⚠ Stash empty")
        wezterm.time.call_after(3, function()
          window:set_right_status("")
        end)
        return
      end
      -- 末尾の改行を除去
      content = content:gsub("\n$", "")
      window:perform_action(wezterm.action.SendString(content), pane)
      window:set_right_status("📋 Popped!")
      wezterm.time.call_after(3, function()
        window:set_right_status("")
      end)
    end),
  },
  -- 直前のコマンドと出力をコピー
  {
    key = "z",
    mods = "LEADER",
    action = wezterm.action_callback(function(window, pane)
      -- コピーモードに入る
      window:perform_action(act.ActivateCopyMode, pane)

      -- 直前のInputゾーン（最後のコマンド）に移動
      window:perform_action(act.CopyMode({ MoveBackwardZoneOfType = "Input" }), pane)

      -- セル選択モードを開始
      window:perform_action(act.CopyMode({ SetSelectionMode = "Cell" }), pane)

      -- 次のPromptゾーンまで選択（コマンドと出力を含む）
      window:perform_action(act.CopyMode({ MoveForwardZoneOfType = "Prompt" }), pane)

      -- 1行上に移動して行末へ（現在のプロンプト行を除外）
      window:perform_action(act.CopyMode("MoveUp"), pane)
      window:perform_action(act.CopyMode("MoveToEndOfLineContent"), pane)

      -- クリップボードにコピー
      window:perform_action(
        act.Multiple({
          { CopyTo = "ClipboardAndPrimarySelection" },
          { Multiple = { "ScrollToBottom", { CopyMode = "Close" } } },
        }),
        pane
      )

      -- ステータスバーに一時的なステータスを表示
      window:set_right_status("📋 Copied!")
      -- 3秒後にクリア
      wezterm.time.call_after(3, function()
        window:set_right_status("")
      end)
    end),
  },
  -- バッファの内容をNeovimで表示（色付き）
  {
    key = "b",
    mods = "LEADER",
    action = wezterm.action_callback(function(window, pane)
      local pane_id = tostring(pane:pane_id())

      -- Neovimの WezCapture コマンドで色付き表示
      local new_pane = pane:split({
        direction = "Right",
        size = 1.0,
        args = {
          os.getenv("SHELL"),
          "-lc",
          "nvim -c 'WezCapture " .. pane_id .. "'",
        },
      })
      new_pane:activate()
      window:perform_action(act.TogglePaneZoomState, new_pane)
    end),
  },
  -- ファジーファインダーでコマンドを選択してオーバーレイペインで実行
  {
    key = "l",
    mods = "LEADER",
    action = act.InputSelector({
      title = "Launch Command",
      choices = {
        { label = "Ghost" },
        { label = "Lazygit" },
        { label = "Neovim" },
        { label = "Yazi" },
      },
      fuzzy = true,
      action = wezterm.action_callback(function(window, pane, _, label)
        if not label then
          return
        end

        local command = ""
        if label == "Ghost" then
          command = "ghost"
        elseif label == "Lazygit" then
          command = "lazygit"
        elseif label == "Neovim" then
          command = "nvim"
        elseif label == "Yazi" then
          command = "yazi"
        end

        local new_pane = pane:split({
          direction = "Bottom",
          size = 1.0,
          args = { os.getenv("SHELL"), "-lc", command },
        })
        window:perform_action(act.TogglePaneZoomState, new_pane)
      end),
    }),
  },
}

local key_tables = {
  copy_mode = {
    -- モードの終了
    { key = "c", mods = "CTRL", action = act.Multiple({ "ScrollToBottom", { CopyMode = "Close" } }) },
    { key = "q", mods = "NONE", action = act.Multiple({ "ScrollToBottom", { CopyMode = "Close" } }) },
    { key = "Escape", mods = "NONE", action = act.Multiple({ "ScrollToBottom", { CopyMode = "Close" } }) },

    -- Vim風のキーバインド
    { key = "h", mods = "NONE", action = act.CopyMode("MoveLeft") },
    { key = "j", mods = "NONE", action = act.CopyMode("MoveDown") },
    { key = "k", mods = "NONE", action = act.CopyMode("MoveUp") },
    { key = "l", mods = "NONE", action = act.CopyMode("MoveRight") },
    { key = "0", mods = "NONE", action = act.CopyMode("MoveToStartOfLine") },
    { key = "^", mods = "NONE", action = act.CopyMode("MoveToStartOfLineContent") },
    { key = "$", mods = "NONE", action = act.CopyMode("MoveToEndOfLineContent") },
    { key = ",", mods = "NONE", action = act.CopyMode("JumpReverse") },
    { key = ";", mods = "NONE", action = act.CopyMode("JumpAgain") },
    { key = "g", mods = "NONE", action = act.CopyMode("MoveToScrollbackTop") },
    { key = "G", mods = "NONE", action = act.CopyMode("MoveToScrollbackBottom") },
    { key = "w", mods = "NONE", action = act.CopyMode("MoveForwardWord") },
    { key = "e", mods = "NONE", action = act.CopyMode("MoveForwardWordEnd") },
    { key = "b", mods = "NONE", action = act.CopyMode("MoveBackwardWord") },
    { key = "t", mods = "NONE", action = act.CopyMode({ JumpForward = { prev_char = true } }) },
    { key = "f", mods = "NONE", action = act.CopyMode({ JumpForward = { prev_char = false } }) },
    { key = "T", mods = "NONE", action = act.CopyMode({ JumpBackward = { prev_char = true } }) },
    { key = "F", mods = "NONE", action = act.CopyMode({ JumpBackward = { prev_char = false } }) },
    { key = "H", mods = "NONE", action = act.CopyMode("MoveToViewportTop") },
    { key = "L", mods = "NONE", action = act.CopyMode("MoveToViewportBottom") },
    { key = "O", mods = "NONE", action = act.CopyMode("MoveToSelectionOtherEndHoriz") },
    { key = "M", mods = "NONE", action = act.CopyMode("MoveToViewportMiddle") },
    { key = "o", mods = "NONE", action = act.CopyMode("MoveToSelectionOtherEnd") },
    { key = "m", mods = "ALT", action = act.CopyMode("MoveToStartOfLineContent") },
    { key = "b", mods = "CTRL", action = act.CopyMode("PageUp") },
    { key = "f", mods = "CTRL", action = act.CopyMode("PageDown") },
    { key = "u", mods = "CTRL", action = act.CopyMode({ MoveByPage = -0.5 }) },
    { key = "d", mods = "CTRL", action = act.CopyMode({ MoveByPage = 0.5 }) },
    { key = "v", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Cell" }) },
    { key = "v", mods = "CTRL", action = act.CopyMode({ SetSelectionMode = "Block" }) },
    { key = "V", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Line" }) },
    {
      key = "y",
      mods = "NONE",
      action = act.Multiple({
        { CopyTo = "ClipboardAndPrimarySelection" },
        -- { Multiple = { "ScrollToBottom", { CopyMode = "Close" } } }, 連続でコピーしたいこともあるのでコメントアウト
      }),
    },

    { key = "p", mods = "ALT|CTRL", action = act.CopyMode("PageUp") },
    { key = "n", mods = "ALT|CTRL", action = act.CopyMode("PageDown") },

    -- 検索結果へジャンプ
    { key = "n", mods = "CTRL", action = act.CopyMode("NextMatch") },
    { key = "p", mods = "CTRL", action = act.CopyMode("PriorMatch") },
    -- 検索モードへ
    { key = "/", mods = "NONE", action = act.Search("CurrentSelectionOrEmptyString") },
    -- ScrollToPrompt
    { key = "[", mods = "ALT", action = act.ScrollToPrompt(-1) },
    { key = "]", mods = "ALT", action = act.ScrollToPrompt(1) },
    -- コマンドの入力領域（Inputゾーン）単位でカーソル移動
    { key = "]", mods = "NONE", action = act.CopyMode({ MoveForwardZoneOfType = "Input" }) }, -- Input, Output, Promptから選択可能
    { key = "[", mods = "NONE", action = act.CopyMode({ MoveBackwardZoneOfType = "Input" }) }, -- Input, Output, Promptから選択可能
    -- セマンティックゾーン選択モード開始（現在位置のゾーン全体を選択）
    { key = "z", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "SemanticZone" }) },
    -- CopyMode中のペーストはモードを終了してからペースト
    {
      key = "v",
      mods = "SUPER",
      action = act.Multiple({
        "ScrollToBottom",
        { CopyMode = "Close" },
        act.PasteFrom("Clipboard"),
      }),
    },
  },

  search_mode = {
    { key = "Escape", mods = "NONE", action = act.CopyMode("Close") },
    -- 検索結果にジャンプしたらコピーモードへ
    {
      key = "n",
      mods = "CTRL",
      action = act.Multiple({
        act.CopyMode("NextMatch"),
        act.ActivateCopyMode,
      }),
    },
    {
      key = "p",
      mods = "CTRL",
      action = act.Multiple({
        act.CopyMode("PriorMatch"),
        act.ActivateCopyMode,
      }),
    },
    { key = "r", mods = "CTRL", action = act.CopyMode("CycleMatchType") },
    { key = "u", mods = "CTRL", action = act.CopyMode("ClearPattern") },
    -- 検索パターンを維持したままコピーモードへ
    { key = "X", mods = "CTRL", action = act.ActivateCopyMode },
  },
  setting_mode = {
    -- Paneサイズの調整
    { key = "h", action = act.AdjustPaneSize({ "Left", 1 }) },
    { key = "l", action = act.AdjustPaneSize({ "Right", 1 }) },
    { key = "k", action = act.AdjustPaneSize({ "Up", 1 }) },
    { key = "j", action = act.AdjustPaneSize({ "Down", 1 }) },

    -- ペインの高さをパーセンテージで設定 (1=10%, 2=20%, ..., 9=90%)
    { key = "1", action = set_pane_height_percent(0.1) },
    { key = "2", action = set_pane_height_percent(0.2) },
    { key = "3", action = set_pane_height_percent(0.3) },
    { key = "4", action = set_pane_height_percent(0.4) },
    { key = "5", action = set_pane_height_percent(0.5) },
    { key = "6", action = set_pane_height_percent(0.6) },
    { key = "7", action = set_pane_height_percent(0.7) },
    { key = "8", action = set_pane_height_percent(0.8) },
    { key = "9", action = set_pane_height_percent(0.9) },

    -- ペインの幅をパーセンテージで設定
    { key = "1", mods = "CTRL", action = set_pane_width_percent(0.1) },
    { key = "2", mods = "CTRL", action = set_pane_width_percent(0.2) },
    { key = "3", mods = "CTRL", action = set_pane_width_percent(0.3) },
    { key = "4", mods = "CTRL", action = set_pane_width_percent(0.4) },
    { key = "5", mods = "CTRL", action = set_pane_width_percent(0.5) },
    { key = "6", mods = "CTRL", action = set_pane_width_percent(0.6) },
    { key = "7", mods = "CTRL", action = set_pane_width_percent(0.7) },
    { key = "8", mods = "CTRL", action = set_pane_width_percent(0.8) },
    { key = "9", mods = "CTRL", action = set_pane_width_percent(0.9) },

    -- 自作モードから抜けるキーバインド設定
    { key = "Escape", action = "PopKeyTable" },
    { key = "q", action = "PopKeyTable" },
    { key = "c", mods = "CTRL", action = "PopKeyTable" },
  },
}

-- augment-command-palette イベントでコマンドパレットにカスタムアクションを追加
wezterm.on("augment-command-palette", function(window, pane)
  local karabiner = require("modules.karabiner_profile")
  local caffeinate = require("modules.caffeinate")

  local commands = {
    {
      brief = "Launch: zsh",
      icon = "md_terminal",
      action = spawn_overlay_pane("zsh"),
    },
    {
      brief = "Launch: Ghost",
      icon = "md_ghost",
      action = spawn_overlay_pane("ghost"),
    },
    {
      brief = "Launch: Lazygit",
      icon = "md_git",
      action = spawn_overlay_pane("lazygit"),
    },
    {
      brief = "Launch: Neovim",
      icon = "md_vim",
      action = spawn_overlay_pane("nvim"),
    },
    {
      brief = "Launch: Yazi",
      icon = "md_folder",
      action = spawn_overlay_pane("yazi"),
    },
    {
      brief = "Launch: Claude Code",
      icon = "md_robot",
      action = spawn_overlay_pane("claude"),
    },
    {
      brief = "GitHub: Browse (gh browse)",
      icon = "md_github",
      action = spawn_overlay_pane("gh browse"),
    },
    {
      brief = "Edit: ~/.aws/config",
      icon = "md_aws",
      action = spawn_overlay_pane("nvim ~/.aws/config"),
    },
    {
      brief = "Edit: ~/.ssh/conf.d/hosts/",
      icon = "md_server",
      action = spawn_overlay_pane("nvim ~/.ssh/conf.d/hosts/"),
    },
    {
      brief = "Edit: ~/.config/gcloud/configurations/",
      icon = "md_cloud",
      action = spawn_overlay_pane("nvim ~/.config/gcloud/configurations/"),
    },
    {
      brief = "VPN: Connect (vpnc)",
      icon = "md_vpn",
      action = spawn_overlay_pane_interactive("vpn-connect-with-fzf"),
    },
    {
      brief = "Weather: wttr.in",
      icon = "md_weather_cloudy",
      action = spawn_overlay_pane("curl wttr.in | less -R"),
    },
  }

  -- Karabinerプロファイルエントリを追加
  for _, cmd in ipairs(karabiner.get_commands()) do
    table.insert(commands, cmd)
  end

  -- Caffeinateエントリを追加
  for _, cmd in ipairs(caffeinate.get_commands()) do
    table.insert(commands, cmd)
  end

  return commands
end)

function module.apply_to_config(config)
  config.disable_default_key_bindings = true
  config.keys = keys
  config.key_tables = key_tables
  config.leader = leader
end

return module
