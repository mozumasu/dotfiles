local wezterm = require("wezterm")

local module = {}

function module.apply_to_config(config)
  -- window_background_opacity = 0.85,
  config.color_scheme = "Kanagawa"
  -- config.color_scheme = "Batman"
  -- config.color_scheme = "Kanagawa (Dragon)"
  -- config.color_scheme = "Sonokai"
  -- config.window_background_opacity = 0.85,

  -- config.  -- window_background_gradient = {
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
end

return module
