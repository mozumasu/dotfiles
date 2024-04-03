
-- pcallで、エラーが発生してもプログラムの実行を中断させないようにする
local ok, _ = pcall(require, 'module_with_error')
if not ok then
  -- not loaded
end


-- Pull in the wezterm API
local wezterm = require 'wezterm'
-- This will hold the configuration.
local config = wezterm.config_builder()

-- colors
-- config.color_scheme = "AdventureTime"
config.macos_window_background_blur = 20
config.window_background_opacity = 0.8
-- font
config.font = wezterm.font("HackGen")
config.font_size = 13.0

-- 最初からフルスクリーンで起動
local mux = wezterm.mux
wezterm.on("gui-startup", function(cmd)
    local tab, pane, window = mux.spawn_window(cmd or {})
    window:gui_window():toggle_fullscreen()
end)

-- and finally, return the configuration to wezterm
return config
