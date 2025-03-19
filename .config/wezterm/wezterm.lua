local wezterm = require("wezterm")
local config = wezterm.config_builder()

local color = require("color")
local keymaps = require("keymaps")
color.apply_to_config(config)
keymaps.apply_to_config(config)

config.font_size = 13.0
config.font = wezterm.font("HackGen Console NF")

return config
