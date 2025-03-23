local wezterm = require("wezterm")
local module = {}

local appearance = {
  -- background
  window_background_opacity = 0.7,
  -- window_background_opacity = 0.85,
  macos_window_background_blur = 13,
  text_background_opacity = 0.8,

  -- window_background_gradient = {
  --   orientation = "Horizontal", -- Horizontal , Vertical
  --   interpolation = "Basis", -- Linear, Basis, CatmullRom
  --   blend = "Oklab", -- Rgb, Hsv, Oklab
  --   noise = 400, -- default 64
  --   -- noise = 180, -- default 64
  --   segment_size = 11,
  --   segment_smoothness = 0.0,
  --   colors = {
  --     "#f8f5e4",
  --     "#ede6d5",
  --     "#faf7ea",
  --     "#eae1ce",
  --     "#fdf9f0",
  --   },
  -- },

  -- font
  font_size = 13.0,
  font = wezterm.font("HackGen Console NF"),

  -- window title
  window_decorations = "RESIZE",

  -- tab
  show_tabs_in_tab_bar = true,
  hide_tab_bar_if_only_one_tab = true,
  tab_bar_at_bottom = true,

  --pane
  inactive_pane_hsb = {
    saturation = 1.0,
    brightness = 0.5,
  },
}

function module.apply_to_config(config)
  for k, v in pairs(appearance) do
    config[k] = v
  end
end

return module
