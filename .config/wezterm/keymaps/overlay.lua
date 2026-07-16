local wezterm = require("wezterm")
local act = wezterm.action

local module = {}

-- オーバーレイペインでコマンドを実行する
-- interactive = true で -lic になり .zshrc の autoload 関数を使える
function module.spawn_overlay_pane(command, interactive)
  return wezterm.action_callback(function(window, pane)
    local new_pane = pane:split({
      direction = "Bottom",
      size = 1.0,
      args = { os.getenv("SHELL"), interactive and "-lic" or "-lc", command },
    })
    window:perform_action(act.TogglePaneZoomState, new_pane)
  end)
end

return module
