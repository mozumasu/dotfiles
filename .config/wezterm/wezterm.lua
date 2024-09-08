local wezterm = require("wezterm")
local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

config.automatically_reload_config = true

config.window_decorations = "RESIZE"
config.window_background_opacity = 0.8
config.macos_window_background_blur = 20

config.window_padding = {
  bottom = 0,
}

config.font_size = 12.0

----------------------------------------------------
-- Tab
----------------------------------------------------
config.show_new_tab_button_in_tab_bar = false
config.show_close_tab_button_in_tabs = false
-- falseにするとタブバーの透過が効かなくなる
-- config.use_fancy_tab_bar = false
-- タブバーを透過する
config.window_background_gradient = {
  colors = { "#000000" },
}

config.window_frame = {
  active_titlebar_bg = "none",
}

-- config.tab_bar.inactive_tab_edge = "none"
config.colors = {
  tab_bar = {
    inactive_tab_edge = "none",
    active_tab = {
      bg_color = "none",
      fg_color = "none",
    },
  },
}

-- The filled in variant of the < symbol
local SOLID_LEFT_ARROW = wezterm.nerdfonts.ple_lower_right_triangle
-- The filled in variant of the > symbol
local SOLID_RIGHT_ARROW = wezterm.nerdfonts.ple_upper_left_triangle

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local edge_background = "none"
  local background = "#5c6d74"
  local foreground = "#FFFFFF"

  if tab.is_active then
    background = "#ae8b2d"
    foreground = "#FFFFFF"
    -- Copy mode
  elseif hover then
    background = "#3b3052"
    foreground = "#FFFFFF"
  end

  local edge_foreground = background

  -- local title = wezterm.truncate_right(tab.active_pane.title, max_width - 2)
  local title = "   " .. wezterm.truncate_right(tab.active_pane.title, max_width - 1) .. "   "

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

-- 最初からフルスクリーンで起動
local mux = wezterm.mux
wezterm.on("gui-startup", function(cmd)
  local tab, pane, window = mux.spawn_window(cmd or {})
  window:gui_window():toggle_fullscreen()
end)

return config
