local wezterm = require("wezterm")
local act = wezterm.action
local module = {}

function module.apply_to_config(config)
  -- 透明度調整のキーを追加
  table.insert(config.key_tables.config_mode, { key = ";", action = act({ EmitEvent = "increase-opacity" }) })
  table.insert(config.key_tables.config_mode, { key = "-", action = act({ EmitEvent = "decrease-opacity" }) })
  table.insert(config.key_tables.config_mode, { key = "0", action = act({ EmitEvent = "reset-opacity" }) })
  table.insert(config.key_tables.config_mode, { key = "9", action = act({ EmitEvent = "reset-color" }) })
  table.insert(config.key_tables.config_mode, { key = "8", action = act({ EmitEvent = "toggle-color-scheme" }) })
end

-- opacity
wezterm.on("decrease-opacity", function(window)
  local overrides = window:get_config_overrides() or {}
  if not overrides.window_background_opacity then
    overrides.window_background_opacity = 1.0
  end
  overrides.window_background_opacity = overrides.window_background_opacity - 0.1
  if overrides.window_background_opacity < 0.1 then
    overrides.window_background_opacity = 0.1
  end
  window:set_config_overrides(overrides)
  -- ここで `config_mode` を再アクティブ化
  window:perform_action(
    wezterm.action.ActivateKeyTable({ name = "config_mode", one_shot = false }),
    window:active_pane()
  )
end)

wezterm.on("increase-opacity", function(window)
  local overrides = window:get_config_overrides() or {}
  if not overrides.window_background_opacity then
    overrides.window_background_opacity = 1.0
  end
  overrides.window_background_opacity = overrides.window_background_opacity + 0.1
  if overrides.window_background_opacity > 1.0 then
    overrides.window_background_opacity = 1.0
  end
  window:set_config_overrides(overrides)
  -- ここで `config_mode` を再アクティブ化
  window:perform_action(
    wezterm.action.ActivateKeyTable({ name = "config_mode", one_shot = false }),
    window:active_pane()
  )
end)

wezterm.on("reset-opacity", function(window, config)
  local overrides = window:get_config_overrides() or {}
  overrides.window_background_opacity = config.window_background_opacity
  window:set_config_overrides(overrides)
  -- ここで `config_mode` を再アクティブ化
  window:perform_action(
    wezterm.action.ActivateKeyTable({ name = "config_mode", one_shot = false }),
    window:active_pane()
  )
end)

return module
