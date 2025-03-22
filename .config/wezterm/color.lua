local wezterm = require("wezterm")

-- エクスポートするモジュールテーブル
local module = {}

-- moduleテーブルで定義されていない関数はexportされない
local function private_helper()
  wezterm.log_error("hello!")
end

-- exportする関数はmoduleテーブルに定義する
-- モジュールテーブルに関数を定義するには`apply_to_config`を使用する
function module.apply_to_config(config)
  private_helper()

  -- config.color_scheme = "Overnight Slumber"
  -- config.color_scheme = "Solarized (dark) (terminal.sexy)"
  -- config.color_scheme = "Solarized Dark - Patched"
  -- config.color_scheme = "Solarized Dark (Gogh)"
  -- config.color_scheme = "Batman"
  -- config.color_scheme = "Kanagawa"
  config.color_scheme = "Kanagawa (Dragon)"
  -- config.color_scheme = "Sonokai"
  -- config.color_scheme = "Everforest (Dark Soft)"
  -- config.color_scheme = "Gruvbox Material (Hard)"
  -- config.color_scheme = "Solarized Dark Higher Contrast"
end

-- モジュールテーブルを返す
return module
