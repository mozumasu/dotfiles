local palette = require("colors")
local module = {}

local appearance = {
  color_scheme = "Solarized Dark Higher Contrast",

  -- window title
  -- タイトルバーを非表示
  window_decorations = "RESIZE", -- NONE, TITLE, TITLE | RESIZE, RESIZE, INTEGRATED_BUTTONS
  window_close_confirmation = "NeverPrompt", -- AlwaysPrompt or NeverPrompt

  -- Pane
  -- 非アクティブPaneの色相と彩度を下げてアクティブPaneと区別する
  inactive_pane_hsb = {
    hue = 0.9,
    saturation = 0.9,
    brightness = 1.0,
  },

  -- タブバーの設定は tab.lua / examples/tab_simple.lua 側で持つ
  -- (format-tab-title の描画前提とセットで管理するため)
  colors = {
    background = palette.background,
    cursor_bg = palette.accent,
    cursor_fg = "#000000",
    cursor_border = palette.accent,
    selection_bg = palette.highlight,
    selection_fg = "#000000",
  },
}

function module.apply_to_config(config)
  for k, v in pairs(appearance) do
    config[k] = v
  end
end

return module
