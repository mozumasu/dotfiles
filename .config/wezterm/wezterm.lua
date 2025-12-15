---@type Wezterm
local wezterm = require("wezterm")

-- ここに設定内容を記述していく
local config = wezterm.config_builder()

-- 設定ファイルの変更を自動で読み込む
config.automatically_reload_config = true

-- macSKK向け: Control-jで改行されないようにする設定
-- https://github.com/mtgto/macSKK?tab=readme-ov-file#q-wezterm-%E3%81%A7-c-j-%E3%82%92%E6%8A%BC%E3%81%99%E3%81%A8%E6%94%B9%E8%A1%8C%E3%81%95%E3%82%8C%E3%81%A6%E3%81%97%E3%81%BE%E3%81%84%E3%81%BE%E3%81%99
---@diagnostic disable-next-line: assign-type-mismatch
config.macos_forward_to_ime_modifier_mask = "SHIFT|CTRL"
config.window_background_opacity = 0.7
config.macos_window_background_blur = 13

config.font_size = 12.0

-- config.colors = {
--   background = "#f8d7e8",
-- }
--

-- 最後に、weztermに設定を戻す
return config
