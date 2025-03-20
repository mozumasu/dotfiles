local wezterm = require("wezterm")
local act = wezterm.action

local module = {}

local leader = { key = "q", mods = "CTRL", timeout_milliseconds = 2000 }
local keys = {
  -- Copy mode
  { key = "X", mods = "CTRL", action = act.ActivateCopyMode },
  -- Command Palette
  { key = "p", mods = "SHIFT|CTRL", action = act.ActivateCommandPalette },
  --  Quick Select: control + shift + space
  { key = "phys:Space", mods = "SHIFT|CTRL", action = act.QuickSelect },
  -- Search mode
  { key = "f", mods = "SUPER", action = act.Search("CurrentSelectionOrEmptyString") },
  -- Zoom mode
  --     { key = "Z", mods = "CTRL", action = act.TogglePaneZoomState },
  { key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
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
  { key = "q", mods = "SUPER", action = act.QuitApplication },
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
  { key = "w", mods = "SUPER", action = act.CloseCurrentTab({ confirm = true }) },
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
  { key = "L", mods = "CTRL", action = act.ShowDebugOverlay },

  -- control + f/b を使用する場合は非有効にする必要がある
  -- { key = "LeftArrow", mods = "NONE", action = act.CopyMode("MoveLeft") },
  -- { key = "RightArrow", mods = "NONE", action = act.CopyMode("MoveRight") },

  -- Scroll
  { key = "PageUp", mods = "SHIFT", action = act.ScrollByPage(-1) },
  { key = "PageUp", mods = "SHIFT|CTRL", action = act.MoveTabRelative(-1) },
  { key = "PageDown", mods = "SHIFT", action = act.ScrollByPage(1) },
  { key = "PageDown", mods = "SHIFT|CTRL", action = act.MoveTabRelative(1) },

  -- Pane
  { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
  { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
  { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
  { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
  -- { key = "h", mods = "SHIFT|CTRL", action = act.ActivatePaneDirection("Left") },
  -- { key = "l", mods = "SHIFT|CTRL", action = act.ActivatePaneDirection("Right") },
  -- { key = "k", mods = "SHIFT|CTRL", action = act.ActivatePaneDirection("Up") },
  -- { key = "j", mods = "SHIFT|CTRL", action = act.ActivatePaneDirection("Down") },

  -- key_tables で設定するため非有効
  -- { key = "LeftArrow", mods = "SHIFT|ALT|CTRL", action = act.AdjustPaneSize({ "Left", 1 }) },
  -- { key = "RightArrow", mods = "SHIFT|ALT|CTRL", action = act.AdjustPaneSize({ "Right", 1 }) },
  -- { key = "UpArrow", mods = "SHIFT|ALT|CTRL", action = act.AdjustPaneSize({ "Up", 1 }) },
  -- { key = "DownArrow", mods = "SHIFT|ALT|CTRL", action = act.AdjustPaneSize({ "Down", 1 }) },

  -- Convert ¥ key to \ (karabiner ver)
  { key = "¥", action = act.SendKey({ key = "¥" }) },
  { key = "¥", mods = "ALT", action = act.SendKey({ key = "\\" }) },
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
    -- scroll
    { key = "PageUp", mods = "NONE", action = act.CopyMode("PageUp") },
    { key = "PageDown", mods = "NONE", action = act.CopyMode("PageDown") },
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
  },
  search_mode = {
    -- close
    { key = "Escape", mods = "NONE", action = act.CopyMode("Close") },
    { key = "n", mods = "CTRL", action = act.CopyMode("NextMatch") },
    { key = "p", mods = "CTRL", action = act.CopyMode("PriorMatch") },
    { key = "u", mods = "CTRL", action = act.CopyMode("ClearPattern") },
    { key = "r", mods = "CTRL", action = act.CopyMode("CycleMatchType") },
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

function module.apply_to_config(config)
  config.disable_default_key_bindings = true
  config.leader = leader
  config.keys = keys
  config.key_tables = key_tables
end

return module
