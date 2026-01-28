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

-- font
config.font_size = 13.0
config.font = wezterm.font("HackGen Console NF")

-- 背景の透過度とぼかし
config.window_background_opacity = 0.7
config.macos_window_background_blur = 13

-- QuickSelect patterns (SUPER + Space)
config.quick_select_patterns = {
  -- AWS ARN
  "\\barn:[\\w\\-]+:[\\w\\-]+:[\\w\\-]*:[0-9]*:[\\w\\-/:]+",
}

require("keymaps").apply_to_config(config)
require("workspace").apply_to_config(config)
require("appearance").apply_to_config(config)
require("tab").apply_to_config(config)
require("statusbar").apply_to_config(config)

-- オプショナルモジュール（keymapsの後に読み込む）
require("modules.opacity").apply_to_config(config)
require("modules.aws_profile").apply_to_config(config)

return config
