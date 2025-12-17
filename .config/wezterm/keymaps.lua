local wezterm = require("wezterm")
local act = wezterm.action

local module = {}

local leader = { key = "q", mods = "CTRL", timeout_milliseconds = 2000 }

local keys = {
  -- 終了
  { key = "q", mods = "SUPER", action = act.QuitApplication },
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
  { key = '"', mods = "ALT|CTRL", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
  { key = "%", mods = "ALT|CTRL", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "LeftArrow", mods = "SHIFT|CTRL", action = act.ActivatePaneDirection("Left") },
  { key = "LeftArrow", mods = "SHIFT|ALT|CTRL", action = act.AdjustPaneSize({ "Left", 1 }) },
  { key = "RightArrow", mods = "SHIFT|CTRL", action = act.ActivatePaneDirection("Right") },
  { key = "RightArrow", mods = "SHIFT|ALT|CTRL", action = act.AdjustPaneSize({ "Right", 1 }) },
  { key = "UpArrow", mods = "SHIFT|CTRL", action = act.ActivatePaneDirection("Up") },
  { key = "UpArrow", mods = "SHIFT|ALT|CTRL", action = act.AdjustPaneSize({ "Up", 1 }) },
  { key = "DownArrow", mods = "SHIFT|CTRL", action = act.ActivatePaneDirection("Down") },
  { key = "DownArrow", mods = "SHIFT|ALT|CTRL", action = act.AdjustPaneSize({ "Down", 1 }) },

  -- フォントサイズ変更
  { key = "+", mods = "SUPER", action = act.IncreaseFontSize },
  { key = "-", mods = "SUPER", action = act.DecreaseFontSize },
  { key = "0", mods = "SUPER", action = act.ResetFontSize },

  { key = "c", mods = "SUPER", action = act.CopyTo("Clipboard") },
  { key = "v", mods = "SUPER", action = act.PasteFrom("Clipboard") },
  { key = "C", mods = "CTRL", action = act.CopyTo("Clipboard") },

  -- 検索
  { key = "F", mods = "CTRL", action = act.Search("CurrentSelectionOrEmptyString") },
  { key = "F", mods = "SHIFT|CTRL", action = act.Search("CurrentSelectionOrEmptyString") },

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
  -- { key = "X", mods = "CTRL", action = act.ActivateCopyMode },
  -- アクティブペインのズーム切替
  { key = "Z", mods = "CTRL", action = act.TogglePaneZoomState },

  -- 誤爆するので非有効にしがち
  { key = "k", mods = "SUPER", action = act.ClearScrollback("ScrollbackOnly") },
  { key = "m", mods = "SUPER", action = act.Hide },
  { key = "H", mods = "CTRL", action = act.HideApplication },

  -- control + space がMaccOSのIME切り替えに使われるので、別のキーに割り当て
  -- { key = "phys:Space", mods = "SHIFT|CTRL", action = act.QuickSelect },
  { key = " ", mods = "SUPER", action = act.QuickSelect },

  -- スクロール
  { key = "PageUp", mods = "SHIFT", action = act.ScrollByPage(-1) },
  { key = "PageDown", mods = "SHIFT", action = act.ScrollByPage(1) },

  -- コピー・ペースト
  { key = "Copy", mods = "NONE", action = act.CopyTo("Clipboard") },
  { key = "Paste", mods = "NONE", action = act.PasteFrom("Clipboard") },

  -- Claude Codeで改行できるようにする
  { key = "Enter", mods = "SHIFT", action = wezterm.action.SendString("\n") },

  -- ScrollToPrompt
  { key = "[", mods = "ALT", action = act.ScrollToPrompt(-1) },
  { key = "]", mods = "ALT", action = act.ScrollToPrompt(1) },

  -- Pane
  { key = "r", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) }, -- Control+q → r 横分割
  { key = "d", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) }, -- Control+q → d 縦分割
  { key = "x", mods = "LEADER", action = act({ CloseCurrentPane = { confirm = true } }) }, -- Control+q → d ペインを閉じる

  -- Search mode
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
  -- <C-h> has been remapped to Backspace, so Backspace must be specified here
  { key = "Backspace", mods = "SHIFT", action = act.ActivatePaneDirection("Left") },
  { key = "l", mods = "SHIFT|CTRL", action = act.ActivatePaneDirection("Right") },
  { key = "k", mods = "SHIFT|CTRL", action = act.ActivatePaneDirection("Up") },
  { key = "j", mods = "SHIFT|CTRL", action = act.ActivatePaneDirection("Down") },
  {
    key = "X",
    mods = "CTRL",
    action = wezterm.action_callback(function(window, pane)
      window:perform_action(act.ActivateCopyMode, pane)
      window:perform_action(act.CopyMode("ClearPattern"), pane)
      window:perform_action(act.CopyMode("ClearSelectionMode"), pane)
      window:perform_action(act.CopyMode("MoveToViewportMiddle"), pane)
    end),
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
        -- { Multiple = { "ScrollToBottom", { CopyMode = "Close" } } },
      }),
    },

    { key = "PageUp", mods = "NONE", action = act.CopyMode("PageUp") },
    { key = "PageDown", mods = "NONE", action = act.CopyMode("PageDown") },
    { key = "End", mods = "NONE", action = act.CopyMode("MoveToEndOfLineContent") },
    { key = "Home", mods = "NONE", action = act.CopyMode("MoveToStartOfLine") },
    { key = "LeftArrow", mods = "NONE", action = act.CopyMode("MoveLeft") },
    { key = "LeftArrow", mods = "ALT", action = act.CopyMode("MoveBackwardWord") },
    { key = "RightArrow", mods = "NONE", action = act.CopyMode("MoveRight") },
    { key = "RightArrow", mods = "ALT", action = act.CopyMode("MoveForwardWord") },
    { key = "UpArrow", mods = "NONE", action = act.CopyMode("MoveUp") },
    { key = "DownArrow", mods = "NONE", action = act.CopyMode("MoveDown") },

    -- 検索結果へジャンプ
    { key = "n", mods = "CTRL", action = act.CopyMode("NextMatch") },
    { key = "p", mods = "CTRL", action = act.CopyMode("PriorMatch") },

    -- 検索モードへ
    { key = "/", mods = "NONE", action = act.Search("CurrentSelectionOrEmptyString") },
  },

  search_mode = {
    { key = "Escape", mods = "NONE", action = act.CopyMode("Close") },
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
    { key = "x", mods = "SHIFT|CTRL", action = act.ActivateCopyMode },
  },
}

function module.apply_to_config(config)
  config.disable_default_key_bindings = true
  config.keys = keys
  config.key_tables = key_tables
  config.leader = leader
end

return module
