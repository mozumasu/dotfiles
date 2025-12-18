local wezterm = require("wezterm")
local module = {}

-- =============================================================================
-- 定数
-- =============================================================================

local WORKSPACE_COLORS = {
  default = "#80EBDF",
  copy_mode = "#ffd700",
  setting_mode = "#39FF14",
}

-- 前回の色を記録（不要な更新を避けるため）
local last_color = nil

-- =============================================================================
-- メイン処理
-- =============================================================================

function module.apply_to_config(_)
  -- ステータスバー更新（ワークスペース名表示 & カーソル色変更）
  wezterm.on("update-status", function(window, pane)
    local workspace = window:active_workspace()
    local key_table = window:active_key_table()
    local color = WORKSPACE_COLORS[key_table] or WORKSPACE_COLORS.default

    -- ワークスペース名の色を変更（全モード対応）
    window:set_left_status(wezterm.format({
      { Background = { Color = "transparent" } },
      { Foreground = { Color = color } },
      { Text = "  " .. workspace .. "  " },
    }))

    -- カーソル色変更（OSCエスケープシーケンスを使用）
    if last_color ~= color then
      last_color = color
      -- OSC 12 でカーソル色を変更: \x1b]12;<color>\x1b\\
      pane:inject_output("\x1b]12;" .. color .. "\x1b\\")
    end
  end)
end

return module
