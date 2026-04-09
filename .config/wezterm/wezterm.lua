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
config.window_background_opacity = 0.9  -- 非フォーカス時のデフォルト（blur見える）
config.macos_window_background_blur = 8  -- opacityで視覚的に制御

-- ステータスバー更新間隔（デフォルト1000ms → 1500ms）
config.status_update_interval = 1500

-- QuickSelect patterns (SUPER + Space)
-- デフォルトパターンを無効化し、パスパターンはプロンプト行頭を除外
config.disable_default_quick_select_patterns = true
config.quick_select_patterns = {
  -- URL
  "\\bhttps?://[\\w\\-._~:/?#@!$&'()*+,;=%]+",
  -- AWS ARN
  "\\barn:[\\w\\-]+:[\\w\\-]+:[\\w\\-]*:[0-9]*:[\\w\\-/:]+",
  -- ファイルパス: スペース・記号の後にあるもののみ（行頭=プロンプトを除外）
  "(?<=[\\s:=(\"'`])(?:~|/)[/\\w\\-.@~]+",
  -- ファイルパス: 行頭かつ行末まで（pwd出力など）。プロンプト行はgit情報が続くので除外される
  "(?m)^(?:~|/)[/\\w\\-.@~]+(?=\\s*$)",
  -- Git commit hash (7-40 chars)
  "\\b[0-9a-f]{7,40}\\b",
  -- IP address
  "\\b(?:[0-9]{1,3}\\.){3}[0-9]{1,3}\\b",
  -- UUID
  "\\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\\b",
  -- kebab-case / snake_case 識別子（2セグメント以上）
  "\\b[a-zA-Z][a-zA-Z0-9]*(?:[_-][a-zA-Z0-9]+){1,}\\b",
  -- メールアドレス
  "\\b[\\w.+-]+@[\\w.-]+\\.[a-zA-Z]{2,}\\b",
}

require("keymaps").apply_to_config(config)
require("workspace").apply_to_config(config)
require("appearance").apply_to_config(config)
require("tab").apply_to_config(config)
require("statusbar").apply_to_config(config)

-- オプショナルモジュール（keymapsの後に読み込む）
require("modules.opacity").apply_to_config(config)
require("modules.aws_profile").apply_to_config(config)
require("modules.karabiner_profile").apply_to_config(config)
require("modules.claude_session").apply_to_config(config)
require("modules.translate").apply_to_config(config)

return config
