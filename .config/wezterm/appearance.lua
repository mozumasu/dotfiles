local wezterm = require("wezterm")
local module = {}

local appearance = {
  -- background
  window_background_opacity = 0.7,
  macos_window_background_blur = 13,

  -- font
  font_size = 13.0,
  font = wezterm.font("HackGen Console NF"),
  unicode_version = 14,

  -- window title
  window_decorations = "RESIZE",
  window_padding = {
    left = 15,
    right = 15,
    top = 15,
    bottom = 0,
  },
  window_content_alignment = {
    horizontal = "Center",
    vertical = "Center",
  },
  window_close_confirmation = "NeverPrompt", -- AlwaysPrompt or NeverPrompt

  --pane
  inactive_pane_hsb = {
    saturation = 1.0,
    brightness = 0.5,
  },

  ----------------------------------------------------
  -- Tab
  ----------------------------------------------------
  show_tabs_in_tab_bar = true,
  hide_tab_bar_if_only_one_tab = true,
  tab_bar_at_bottom = true,
  show_new_tab_button_in_tab_bar = false,
  show_close_tab_button_in_tabs = false, -- Can only be used in nightly
  tab_max_width = 30,
  use_fancy_tab_bar = false,
  -- Hide borders between tabs
  colors = {
    tab_bar = {
      background = "none",
      inactive_tab_edge = "none",
    },
  },
}

require("tab")

function module.apply_to_config(config)
  for k, v in pairs(appearance) do
    config[k] = v
  end
end

return module
