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

  config.color_scheme = "Batman"
end

-- モジュールテーブルを返す
return module
