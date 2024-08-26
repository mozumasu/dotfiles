local wezterm = require("wezterm")

local config = {}

if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- keybinds
config.disable_default_key_bindings = true
config.keys = require("keybinds").keys
config.key_tables = require("keybinds").key_tables
config.leader = { key = "q", mods = "CTRL", timeout_milliseconds = 2000 }

-- colors
--
-- config.color_scheme = "AdventureTime"
config.macos_window_background_blur = 20
config.window_background_opacity = 0.9

-- config.window_background_gradient = {
-- 	colors = { "#03001e", "#1565C0" },
-- 	-- Specifices a Linear gradient starting in the top left corner.
-- 	orientation = { Linear = { angle = -45.0 } },
-- }
-- font
config.font = wezterm.font("Hack")
config.font_size = 13.0

-- 最初からフルスクリーンで起動
local mux = wezterm.mux
wezterm.on("gui-startup", function(cmd)
	local tab, pane, window = mux.spawn_window(cmd or {})
	window:gui_window():toggle_fullscreen()
end)

-- and finally, return the configuration to wezterm
return config
