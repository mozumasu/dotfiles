local wezterm = require("wezterm")
local act = wezterm.action
local resize = require("keymaps.pane_resize")

local close_copy_mode = act.Multiple({ "ScrollToBottom", { CopyMode = "Close" } })

local copy_mode = {
  -- モードの終了
  { key = "c", mods = "CTRL", action = close_copy_mode },
  { key = "q", mods = "NONE", action = close_copy_mode },
  { key = "Escape", mods = "NONE", action = close_copy_mode },
  -- key table はグローバルの C-[ → esc 変換より先に評価されるためここでも esc 相当を定義する
  { key = "[", mods = "CTRL", action = close_copy_mode },

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
}

local search_mode = {
  { key = "Escape", mods = "NONE", action = act.CopyMode("Close") },
  { key = "[", mods = "CTRL", action = act.CopyMode("Close") },
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
}

local setting_mode = {
  -- Paneサイズの調整
  { key = "h", action = act.AdjustPaneSize({ "Left", 1 }) },
  { key = "l", action = act.AdjustPaneSize({ "Right", 1 }) },
  { key = "k", action = act.AdjustPaneSize({ "Up", 1 }) },
  { key = "j", action = act.AdjustPaneSize({ "Down", 1 }) },

  -- 自作モードから抜けるキーバインド設定
  { key = "Escape", action = "PopKeyTable" },
  { key = "[", mods = "CTRL", action = "PopKeyTable" },
  { key = "q", action = "PopKeyTable" },
  { key = "c", mods = "CTRL", action = "PopKeyTable" },
}

-- ペインの高さ/幅をパーセンテージで設定 (1=10%, ..., 9=90%。無修飾=高さ / CTRL=幅)
for i = 1, 9 do
  table.insert(setting_mode, { key = tostring(i), action = resize.set_pane_height_percent(i / 10) })
  table.insert(setting_mode, { key = tostring(i), mods = "CTRL", action = resize.set_pane_width_percent(i / 10) })
end

return {
  copy_mode = copy_mode,
  search_mode = search_mode,
  setting_mode = setting_mode,
}
