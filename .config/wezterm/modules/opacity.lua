local wezterm = require("wezterm")
local act = wezterm.action
local module = {}

function module.apply_to_config(config)
  -- 透明度調整のキーを追加
  table.insert(config.key_tables.setting_mode, { key = ";", action = act.EmitEvent("increase-opacity") })
  table.insert(config.key_tables.setting_mode, { key = "-", action = act.EmitEvent("decrease-opacity") })
  table.insert(config.key_tables.setting_mode, { key = "0", action = act.EmitEvent("reset-opacity") })
end

local function reactivate_setting_mode(window)
  window:perform_action(
    wezterm.action.ActivateKeyTable({ name = "setting_mode", one_shot = false }),
    window:active_pane()
  )
end

local function adjust_opacity(window, delta, config)
  local overrides = window:get_config_overrides() or {}
  local current = overrides.window_background_opacity or config.window_background_opacity or 1.0

  local new_opacity = current + delta
  new_opacity = math.max(0.1, math.min(1.0, new_opacity))

  overrides.window_background_opacity = new_opacity
  window:set_config_overrides(overrides)

  reactivate_setting_mode(window)
end

wezterm.on("decrease-opacity", function(window, config)
  adjust_opacity(window, -0.1, config)
end)

wezterm.on("increase-opacity", function(window, config)
  adjust_opacity(window, 0.1, config)
end)

wezterm.on("reset-opacity", function(window, config)
  local overrides = window:get_config_overrides() or {}
  overrides.window_background_opacity = config.window_background_opacity
  window:set_config_overrides(overrides)

  reactivate_setting_mode(window)
end)

return module
