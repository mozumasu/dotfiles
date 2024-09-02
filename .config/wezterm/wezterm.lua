local wezterm = require("wezterm")

local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- local scheme = wezterm.get_builtin_color_schemes()["nord"]
----------------------------------------------------
-- Tab
----------------------------------------------------
-- config.tab_bar_at_bottom = false
-- The filled in variant of the < symbol
local SOLID_LEFT_ARROW = wezterm.nerdfonts.pl_right_hard_divider

-- The filled in variant of the > symbol
local SOLID_RIGHT_ARROW = wezterm.nerdfonts.pl_left_hard_divider
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  -- local tab_index = tab.tab_index + 1
  local edge_background = "#050606"
  local background = "#1b1032"
  local foreground = "#808080"

  if tab.is_active then
    background = "#2b2042"
    foreground = "#c0c0c0"
    -- Copy mode
  elseif hover then
    background = "#3b3052"
    foreground = "#909090"
  end

  local edge_foreground = background

  -- ensure that the titles fit in the available space,
  -- and that we have room for the edges.
  local title = wezterm.truncate_right(tab.active_pane.title, max_width - 2)

  return {
    -- { string.format(" %d ", tab_index) },
    { Background = { Color = edge_background } },
    { Foreground = { Color = edge_foreground } },
    { Text = SOLID_LEFT_ARROW },
    { Background = { Color = background } },
    { Foreground = { Color = foreground } },
    { Text = title },
    { Background = { Color = edge_background } },
    { Foreground = { Color = edge_foreground } },
    { Text = SOLID_RIGHT_ARROW },
  }
end)

----------------------------------------------------
-- keybinds
----------------------------------------------------
config.disable_default_key_bindings = true
config.keys = require("keybinds").keys
config.key_tables = require("keybinds").key_tables
config.leader = { key = "q", mods = "CTRL", timeout_milliseconds = 2000 }

----------------------------------------------------
-- colors
----------------------------------------------------
-- config.color_scheme = "#041319"
-- config.color_scheme = "AdventureTime"
config.macos_window_background_blur = 20
config.window_background_opacity = 0.9

-- config.window_background_gradient = {
-- 	colors = { "#03001e", "#1565C0" },
-- 	-- Specifies a Linear gradient starting in the top left corner.
-- 	orientation = { Linear = { angle = -45.0 } },
-- }
----------------------------------------------------
-- font
----------------------------------------------------
-- config.font = wezterm.font("Hack Nerd Font")
config.font_size = 13.0

-- 最初からフルスクリーンで起動
local mux = wezterm.mux
wezterm.on("gui-startup", function(cmd)
  local tab, pane, window = mux.spawn_window(cmd or {})
  window:gui_window():toggle_fullscreen()
end)

-- and finally, return the configuration to wezterm
return config
