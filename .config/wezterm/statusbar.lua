local wezterm = require("wezterm")
local palette = require("colors")
local module = {}

-- =============================================================================
-- 定数
-- =============================================================================

-- active_key_table() の名前 -> 表示色
local KEY_TABLE_COLORS = {
  default = palette.accent,
  copy_mode = palette.highlight,
  setting_mode = "#39FF14",
}

-- pane ごとに前回注入したカーソル色を記録（不要な再注入を避けるため）
local last_cursor_color = {}

-- =============================================================================
-- メイン処理
-- =============================================================================

function module.apply_to_config(_)
  -- ステータスバー更新（ワークスペース名表示 & カーソル色変更）
  wezterm.on("update-status", function(window, pane)
    local workspace = window:active_workspace()
    local key_table = window:active_key_table()
    local color = KEY_TABLE_COLORS[key_table] or KEY_TABLE_COLORS.default

    -- ワークスペース名の色を変更（全モード対応）
    window:set_left_status(wezterm.format({
      { Background = { Color = "transparent" } },
      { Foreground = { Color = color } },
      { Text = "  " .. workspace .. "  " },
    }))

    -- カーソル色変更（OSCエスケープシーケンスを使用）
    -- 色の注入は pane 単位でしか効かないため、記録も pane 単位で持つ
    local pane_id = pane:pane_id()
    if last_cursor_color[pane_id] ~= color then
      last_cursor_color[pane_id] = color
      -- OSC 12 でカーソル色を変更: \x1b]12;<color>\x1b\\
      pane:inject_output("\x1b]12;" .. color .. "\x1b\\")
    end
  end)
end

return module
