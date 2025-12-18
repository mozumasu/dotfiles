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

-- =============================================================================
-- メイン処理
-- =============================================================================

function module.apply_to_config(_)
  -- ステータスバー更新（ワークスペース名表示）
  wezterm.on("update-status", function(window, _)
    local workspace = window:active_workspace()
    local key_table = window:active_key_table()
    local color = WORKSPACE_COLORS[key_table] or WORKSPACE_COLORS.default

    window:set_left_status(wezterm.format({
      { Foreground = { Color = color } },
      { Text = "  " .. workspace .. "  " },
    }))
  end)
end

return module
