local wezterm = require("wezterm")
local act = wezterm.action
local toggle_term = require("toggle_term")
local edit_prompt = require("edit_prompt")
local workspace = require("workspace")
local translate = require("translate")

local module = {}

local leader = { key = "q", mods = "CTRL", timeout_milliseconds = 2000 }

local keys = {
  -- Terminal pane toggle (bottom)
  toggle_term.toggle_term(),
  -- Terminal pane toggle (right)
  toggle_term.toggle_term_right(),

  -- Treat Alt as Meta while keeping backslash functionality (Alt+¥)
  { key = "¥", mods = "ALT", action = wezterm.action.SendString("\\") },
  -- Zoom current pane
  { key = "z", mods = "SHIFT|CTRL", action = act.TogglePaneZoomState },
  { key = "s", mods = "SHIFT|CTRL", action = act.PaneSelect },

  -- EditPrompt for Claude Code
  edit_prompt.edit_prompt(), -- Ctrl+A: Open nvim in split pane

  -- Copy mode
  -- { key = "X", mods = "CTRL", action = act.ActivateCopyMode },
  -- 検索ワードをクリアにして Copy mode
  {
    key = "X",
    mods = "CTRL",
    action = wezterm.action_callback(function(window, pane)
      window:perform_action(act.CopyMode("ClearPattern"), pane)
      window:perform_action(act.ActivateCopyMode, pane)
      window:perform_action(act.CopyMode("MoveToViewportMiddle"), pane)
    end),
  },
  -- Command Palette
  { key = "p", mods = "SHIFT|CTRL", action = act.ActivateCommandPalette },
  --  Quick Select: control + shift + space
  { key = "phys:Space", mods = "SHIFT|CTRL", action = act.QuickSelect },
  -- Search mode
  -- { key = "f", mods = "SUPER", action = act.Search("CurrentSelectionOrEmptyString") },
  {
    key = "f",
    mods = "SUPER",
    action = wezterm.action_callback(function(window, pane)
      window:perform_action(act.Search("CurrentSelectionOrEmptyString"), pane)
      window:perform_action(
        act.Multiple({
          act.CopyMode("ClearPattern"),
          act.CopyMode("ClearSelectionMode"),
        }),
        pane
      )
    end),
  },
  -- Copy last command and its output
  {
    key = "z",
    mods = "LEADER",
    action = wezterm.action_callback(function(window, pane)
      -- Enter copy mode
      window:perform_action(act.ActivateCopyMode, pane)

      -- Move to the previous Input zone (last command)
      window:perform_action(act.CopyMode({ MoveBackwardZoneOfType = "Input" }), pane)

      -- Start cell selection mode
      window:perform_action(act.CopyMode({ SetSelectionMode = "Cell" }), pane)

      -- Select up to the next Prompt zone (includes command and output)
      window:perform_action(act.CopyMode({ MoveForwardZoneOfType = "Prompt" }), pane)

      -- Move up one line and to end of line (exclude current prompt line)
      window:perform_action(act.CopyMode("MoveUp"), pane)
      window:perform_action(act.CopyMode("MoveToEndOfLineContent"), pane)

      -- Copy to clipboard
      window:perform_action(
        act.Multiple({
          { CopyTo = "ClipboardAndPrimarySelection" },
          { Multiple = { "ScrollToBottom", { CopyMode = "Close" } } },
        }),
        pane
      )

      -- Show temporary status in status bar
      window:set_right_status("📋 Copied!")
      -- Clear after 3 seconds
      wezterm.time.call_after(3, function()
        window:set_right_status("")
      end)
    end),
  },
  -- Zoom mode (moved from leader+z to leader+Z)
  { key = "Z", mods = "LEADER", action = act.TogglePaneZoomState },
  -- View terminal history in nvim
  {
    key = "a",
    mods = "LEADER",
    action = wezterm.action_callback(function(window, pane)
      local dims = pane:get_dimensions()
      local new_pane = pane:split({
        direction = "Right",
        size = 1.0,
        args = {
          os.getenv("SHELL"),
          "-lc",
          "wezterm cli get-text --pane-id="
            .. pane:pane_id()
            .. " --start-line -999999 --escapes | nvim -R "
            .. "-c 'silent! BaleiaColorize' "
            .. "-c 'normal! G' -",
        },
      })
      new_pane:activate()
      window:perform_action(act.TogglePaneZoomState, new_pane)
    end),
  },
  -- Char select
  {
    key = "U",
    mods = "CTRL",
    action = act.CharSelect({ copy_on_select = true, copy_to = "ClipboardAndPrimarySelection" }),
  },

  -- custom mode
  { key = "s", mods = "LEADER", action = act.ActivateKeyTable({ name = "setting_mode", one_shot = false }) },

  -- Application
  { key = "h", mods = "SUPER", action = act.HideApplication },

  -- Window
  { key = "Enter", mods = "ALT", action = act.ToggleFullScreen },
  -- { key = "q", mods = "SUPER", action = act.QuitApplication },
  { key = "n", mods = "SUPER", action = act.SpawnWindow },
  { key = "m", mods = "SUPER", action = act.Hide },

  -- Pane
  { key = "d", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
  { key = "r", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "x", mods = "LEADER", action = act({ CloseCurrentPane = { confirm = true } }) },

  -- Tab
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
  { key = "w", mods = "SUPER", action = act.CloseCurrentTab({ confirm = false }) },
  { key = "t", mods = "SUPER", action = act.SpawnTab("CurrentPaneDomain") },

  -- Font
  { key = "0", mods = "SUPER", action = act.ResetFontSize },
  { key = "+", mods = "SUPER", action = act.IncreaseFontSize },
  { key = "-", mods = "SUPER", action = act.DecreaseFontSize },

  -- Clipborad
  { key = "v", mods = "SUPER", action = act.PasteFrom("Clipboard") },
  { key = "c", mods = "SUPER", action = act.CopyTo("Clipboard") },
  { key = "Copy", mods = "NONE", action = act.CopyTo("Clipboard") },
  { key = "Paste", mods = "NONE", action = act.PasteFrom("Clipboard") },

  -- Reload
  { key = "R", mods = "CTRL", action = act.ReloadConfiguration },

  -- Other
  { key = "K", mods = "CTRL", action = act.ClearScrollback("ScrollbackOnly") },
  { key = "k", mods = "SUPER", action = act.ClearScrollback("ScrollbackOnly") },
  { key = "L", mods = "SUPER", action = act.ShowDebugOverlay },

  -- Claude Code
  { key = "Enter", mods = "SHIFT", action = wezterm.action.SendString("\n") },

  -- control + f/b を使用する場合は非有効にする必要がある
  -- { key = "LeftArrow", mods = "NONE", action = act.CopyMode("MoveLeft") },
  -- { key = "RightArrow", mods = "NONE", action = act.CopyMode("MoveRight") },

  -- Scroll
  { key = "PageUp", mods = "SHIFT", action = act.ScrollByPage(-0.01) },
  { key = "PageUp", mods = "SHIFT|CTRL", action = act.MoveTabRelative(-1) },
  { key = "PageDown", mods = "SHIFT", action = act.ScrollByPage(0.02) },
  { key = "PageDown", mods = "SHIFT|CTRL", action = act.MoveTabRelative(1) },
  { key = "p", mods = "ALT|CTRL", action = act.ScrollByPage(-0.5) },
  { key = "n", mods = "ALT|CTRL", action = act.ScrollByPage(0.5) },

  -- Pane
  { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
  { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
  { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
  { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
  -- <C-h> has been remapped to Backspace, so Backspace must be specified here
  { key = "Backspace", mods = "SHIFT", action = act.ActivatePaneDirection("Left") },
  { key = "l", mods = "SHIFT|CTRL", action = act.ActivatePaneDirection("Right") },
  { key = "k", mods = "SHIFT|CTRL", action = act.ActivatePaneDirection("Up") },
  { key = "j", mods = "SHIFT|CTRL", action = act.ActivatePaneDirection("Down") },

  -- key_tables で設定するため非有効
  -- { key = "LeftArrow", mods = "SHIFT|ALT|CTRL", action = act.AdjustPaneSize({ "Left", 1 }) },
  -- { key = "RightArrow", mods = "SHIFT|ALT|CTRL", action = act.AdjustPaneSize({ "Right", 1 }) },
  -- { key = "UpArrow", mods = "SHIFT|ALT|CTRL", action = act.AdjustPaneSize({ "Up", 1 }) },
  -- { key = "DownArrow", mods = "SHIFT|ALT|CTRL", action = act.AdjustPaneSize({ "Down", 1 }) },

  {
    key = ",",
    mods = "SUPER",
    action = wezterm.action.SplitPane({
      direction = "Right",
      size = { Percent = 50 },
      command = {
        args = {
          os.getenv("SHELL"),
          "-c",
          "nvim " .. wezterm.shell_quote_arg(wezterm.config_dir),
        },
      },
    }),
  },
  -- ScrollToPrompt
  { key = "[", mods = "ALT", action = act.ScrollToPrompt(-1) },
  { key = "]", mods = "ALT", action = act.ScrollToPrompt(1) },

  {
    key = ".",
    mods = "SUPER",
    action = wezterm.action.SplitPane({
      direction = "Right",
      size = { Percent = 50 },
      command = {
        args = {
          os.getenv("SHELL"),
          "-l",
          "-c",
          [[
          export FZF_DEFAULT_COMMAND="man -k . | awk -F ' - ' '{print \$1}' | sed 's/(.*)//' | sort -u"
          cmd=$(fzf --height=40% --reverse --prompt='man> ')
          if [ -n "$cmd" ]; then
            command man "$cmd" 2>&1 | col -bx | nvim -R -c 'set ft=man' -
          fi
          ]],
        },
      },
    }),
  },
  -- ShowLauncher
  -- { key = "l", mods = "SUPER", action = wezterm.action.ShowLauncher }, -- default: Alt + l
  {
    key = ";",
    mods = "ALT",
    action = wezterm.action.ShowLauncherArgs({ flags = "FUZZY|TABS" }),
  },
  {
    key = "p",
    mods = "LEADER",
    action = wezterm.action.ShowLauncherArgs({
      title = "🎛 カスタムメニュー",
      flags = "LAUNCH_MENU_ITEMS|WORKSPACES",
    }),
  },
  -- InputSelector
  {
    key = "E",
    mods = "CTRL",
    action = act.InputSelector({
      action = wezterm.action_callback(function(_, pane, id, label)
        if not id and not label then
          wezterm.log_info("cancelled")
        else
          wezterm.log_info("you selected ", id, label)
          pane:send_text(id)
        end
      end),
      title = "I am title",
      choices = {
        -- This is the first entry
        {
          -- Here we're using wezterm.format to color the text.
          -- You can just use a string directly if you don't want
          -- to control the colors
          label = wezterm.format({
            { Foreground = { AnsiColor = "Red" } },
            { Text = "No" },
            { Foreground = { AnsiColor = "Green" } },
            { Text = " thanks" },
          }),
          -- This is the text that we'll send to the terminal when
          -- this entry is selected
          id = "Regretfully, I decline this offer.",
        },
        -- This is the second entry
        {
          label = "WTF?",
          id = "An interesting idea, but I have some questions about it.",
        },
        -- This is the third entry
        {
          label = "LGTM",
          id = "This sounds like the right choice",
        },
      },
    }),
  },
  {
    key = "]",
    mods = "SUPER|SHIFT",
    action = wezterm.action.ToggleAlwaysOnTop,
  },
  -- Skip scratch workspace when switching workspaces
  { key = "n", mods = "CTRL|CMD", action = workspace.switch_to_next_workspace_skip_scratch() },
  { key = "p", mods = "CTRL|CMD", action = workspace.switch_to_prev_workspace_skip_scratch() },
}

local key_tables = {
  copy_mode = {
    -- Quit
    { key = "Escape", mods = "NONE", action = act.Multiple({ "ScrollToBottom", { CopyMode = "Close" } }) },
    { key = "c", mods = "CTRL", action = act.Multiple({ "ScrollToBottom", { CopyMode = "Close" } }) },
    { key = "q", mods = "NONE", action = act.Multiple({ "ScrollToBottom", { CopyMode = "Close" } }) },
    -- { key = "g", mods = "CTRL", action = act.Multiple({ "ScrollToBottom", { CopyMode = "Close" } }) },

    -- { key = "Tab", mods = "NONE", action = act.CopyMode("MoveForwardWord") },
    -- { key = "Tab", mods = "SHIFT", action = act.CopyMode("MoveBackwardWord") },

    -- vim like
    { key = "h", mods = "NONE", action = act.CopyMode("MoveLeft") },
    { key = "j", mods = "NONE", action = act.CopyMode("MoveDown") },
    { key = "k", mods = "NONE", action = act.CopyMode("MoveUp") },
    { key = "l", mods = "NONE", action = act.CopyMode("MoveRight") },
    { key = "Enter", mods = "NONE", action = act.CopyMode("MoveToStartOfNextLine") },
    { key = "0", mods = "NONE", action = act.CopyMode("MoveToStartOfLine") },
    { key = "^", mods = "NONE", action = act.CopyMode("MoveToStartOfLineContent") },
    -- { key = "m", mods = "ALT", action = act.CopyMode("MoveToStartOfLineContent") },
    { key = "$", mods = "NONE", action = act.CopyMode("MoveToEndOfLineContent") },
    -- move word
    { key = "w", mods = "NONE", action = act.CopyMode("MoveForwardWord") },
    { key = "b", mods = "NONE", action = act.CopyMode("MoveBackwardWord") },
    { key = "e", mods = "NONE", action = act.CopyMode("MoveForwardWordEnd") },
    -- move cursor
    { key = "f", mods = "NONE", action = act.CopyMode({ JumpForward = { prev_char = false } }) },
    { key = "F", mods = "NONE", action = act.CopyMode({ JumpBackward = { prev_char = false } }) },
    { key = "t", mods = "NONE", action = act.CopyMode({ JumpForward = { prev_char = true } }) },
    { key = "T", mods = "NONE", action = act.CopyMode({ JumpBackward = { prev_char = true } }) },
    { key = ";", mods = "NONE", action = act.CopyMode("JumpAgain") },
    { key = ",", mods = "NONE", action = act.CopyMode("JumpReverse") },
    -- select
    { key = "v", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Cell" }) },
    { key = "V", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Line" }) },
    { key = "v", mods = "CTRL", action = act.CopyMode({ SetSelectionMode = "Block" }) },
    { key = "Space", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Cell" }) },
    { key = "O", mods = "NONE", action = act.CopyMode("MoveToSelectionOtherEndHoriz") },
    { key = "o", mods = "NONE", action = act.CopyMode("MoveToSelectionOtherEnd") },
    -- yank
    {
      key = "y",
      mods = "NONE",
      action = act.Multiple({
        { CopyTo = "ClipboardAndPrimarySelection" },
        { Multiple = { "ScrollToBottom", { CopyMode = "Close" } } },
      }),
    },
    -- yank and translate
    {
      key = "Y",
      mods = "NONE",
      action = wezterm.action_callback(function(window, pane)
        -- Copy Modeが開いている間に選択テキストを取得
        local text = window:get_selection_text_for_pane(pane)

        -- クリップボードにコピー
        window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)

        -- Copy Modeを閉じる
        window:perform_action(act.Multiple({ "ScrollToBottom", { CopyMode = "Close" } }), pane)

        -- 翻訳を直接実行
        if text and text ~= "" then
          translate.translate_text_in_pane(text, window, pane)
        end
      end),
    },
    -- scroll
    { key = "PageUp", mods = "NONE", action = act.CopyMode("PageUp") },
    { key = "PageDown", mods = "NONE", action = act.CopyMode("PageDown") },
    { key = "p", mods = "ALT|CTRL", action = act.CopyMode("PageUp") },
    { key = "n", mods = "ALT|CTRL", action = act.CopyMode("PageDown") },
    { key = "e", mods = "CTRL", action = act.ScrollByPage(-0.01) },
    { key = "y", mods = "CTRL", action = act.ScrollByPage(0.02) },
    { key = "u", mods = "CTRL", action = act.CopyMode({ MoveByPage = -0.5 }) },
    { key = "d", mods = "CTRL", action = act.CopyMode({ MoveByPage = 0.5 }) },
    { key = "g", mods = "NONE", action = act.CopyMode("MoveToScrollbackTop") },
    { key = "G", mods = "NONE", action = act.CopyMode("MoveToScrollbackBottom") },
    { key = "H", mods = "NONE", action = act.CopyMode("MoveToViewportTop") },
    { key = "L", mods = "NONE", action = act.CopyMode("MoveToViewportBottom") },
    { key = "M", mods = "NONE", action = act.CopyMode("MoveToViewportMiddle") },
    -- emacs like
    { key = "f", mods = "ALT", action = act.CopyMode("MoveForwardWord") },
    { key = "b", mods = "ALT", action = act.CopyMode("MoveBackwardWord") },
    -- { key = "b", mods = "CTRL", action = act.CopyMode("PageUp") },
    -- { key = "f", mods = "CTRL", action = act.CopyMode("PageDown") },
    -- ScrollToPrompt
    { key = "[", mods = "ALT", action = act.ScrollToPrompt(-1) },
    { key = "]", mods = "ALT", action = act.ScrollToPrompt(1) },

    -- コマンドの入力領域（Inputゾーン）単位でカーソル移動
    { key = "]", mods = "NONE", action = act.CopyMode({ MoveForwardZoneOfType = "Input" }) }, -- Input, Output, Prompt
    { key = "[", mods = "NONE", action = act.CopyMode({ MoveBackwardZoneOfType = "Input" }) }, -- Input, Output, Prompt

    -- 検索ワードを編集
    -- { key = "e", mods = "CTRL", action = act.CopyMode("EditPattern") },
    { key = "q", mods = "CTRL", action = act.CopyMode("AcceptPattern") }, -- 明示的に設定してもOK
    { key = "c", mods = "CTRL", action = act.CopyMode("ClearPattern") }, -- キャンセル用カーソル移動

    -- セマンティックゾーン選択モード開始（現在位置のゾーン全体を選択）
    { key = "z", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "SemanticZone" }) },
    -- Copy Mode → Search mode
    { key = "/", mods = "NONE", action = act.Search("CurrentSelectionOrEmptyString") },
    { key = "n", mods = "CTRL", action = act.CopyMode("NextMatch") },
    { key = "p", mods = "CTRL", action = act.CopyMode("PriorMatch") },
  },
  search_mode = {
    -- close
    -- { key = "Escape", mods = "NONE", action = act.CopyMode("Close") },
    { key = "n", mods = "CTRL", action = act.CopyMode("NextMatch") },
    { key = "p", mods = "CTRL", action = act.CopyMode("PriorMatch") },
    { key = "u", mods = "CTRL", action = act.CopyMode("ClearPattern") },
    { key = "r", mods = "CTRL", action = act.CopyMode("CycleMatchType") },

    -- -- Escape キーで検索だけキャンセル（Copy Mode 継続）
    -- { key = "Escape", mods = "NONE", action = act.CopyMode("ClearPattern") },
    { key = "c", mods = "CTRL", action = act.Multiple({ "ScrollToBottom", { CopyMode = "Close" } }) },
    -- -- Cancel the mode
    -- { key = "Escape", action = "PopKeyTable" },
    -- { key = "q", action = "PopKeyTable" },
    -- { key = "c", mod = "CTRL", action = "PopKeyTable" },
    { key = "X", mods = "CTRL", action = act.ActivateCopyMode },
  },
  -- custom key tables
  setting_mode = {
    { key = "h", action = act.AdjustPaneSize({ "Left", 1 }) },
    { key = "l", action = act.AdjustPaneSize({ "Right", 1 }) },
    { key = "k", action = act.AdjustPaneSize({ "Up", 1 }) },
    { key = "j", action = act.AdjustPaneSize({ "Down", 1 }) },

    -- Cancel the mode
    { key = "Escape", action = "PopKeyTable" },
    { key = "q", action = "PopKeyTable" },
    { key = "c", mod = "CTRL", action = "PopKeyTable" },
  },
}

local mouse_bindings = {
  {
    event = { Down = { streak = 3, button = "Left" } },
    action = wezterm.action.SelectTextAtMouseCursor("SemanticZone"),
    mods = "NONE",
  },
}

function module.apply_to_config(config)
  config.disable_default_key_bindings = true
  config.leader = leader
  config.keys = keys
  config.key_tables = key_tables
  config.mouse_bindings = mouse_bindings
end

return module
