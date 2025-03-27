local wezterm = require("wezterm")

local module = {}

function module.apply_to_config(config)
  -- config.color_scheme = "Overnight Slumber"
  -- config.color_scheme = "Solarized Dark - Patched"
  config.color_scheme = "Solarized Dark Higher Contrast"
end

return module
