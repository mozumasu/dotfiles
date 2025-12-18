local wezterm = require("wezterm")
local module = {}

local appearance = {

  -- window title
  -- タイトルバーを非表示
  window_decorations = "RESIZE", -- NONE, TITLE, TITLE | RESIZE, RESIZE, INTEGRATED_BUTTONS
  window_close_confirmation = "NeverPrompt", -- AlwaysPrompt or NeverPrompt

  -- Pane
  inactive_pane_hsb = {
    saturation = 0.5,
    brightness = 1.0,
  },

  -- Tab
  show_tabs_in_tab_bar = true,
  hide_tab_bar_if_only_one_tab = false,
  tab_bar_at_bottom = true,
  show_new_tab_button_in_tab_bar = false,
  show_close_tab_button_in_tabs = false, -- Can only be used in nightly
  tab_max_width = 30,
  use_fancy_tab_bar = true,
  -- use_fancy_tab_bar = trueの場合のタブバー透過設定
  window_frame = {
    inactive_titlebar_bg = "none",
    active_titlebar_bg = "none",
  },
  -- Hide borders between tabs
  colors = {
    -- use_fancy_tab_bar = falseの場合のタブバー透過設定
    tab_bar = {
      background = "none",
      inactive_tab_edge = "none",
    },
  },
}

function module.apply_to_config(config)
  for k, v in pairs(appearance) do
    config[k] = v
  end
end

return module
