local wezterm = require("wezterm")
local module = {}

local appearance = {
  -- background
  window_background_opacity = 0.7,
  macos_window_background_blur = 13,

  -- font
  font_size = 13.0,
  font = wezterm.font("HackGen Console NF"),
  unicode_version = 14,

  -- window title
  window_decorations = "RESIZE", -- NONE, TITLE, TITLE | RESIZE, RESIZE, INTEGRATED_BUTTONS
  -- only for INTEGRATED_BUTTONS
  -- integrated_title_button_alignment = "Right",
  -- integrated_title_button_color = "Auto",
  -- integrated_title_button_style = "MacOsNative", -- Windows, Gnome, MacOsNative
  -- integrated_title_buttons = { "Hide", "Maximize", "Close" },

  window_padding = {
    left = 15,
    right = 15,
    top = 15,
    bottom = 0,
  },
  -- Disabled due to unstable font rendering
  -- window_content_alignment = {
  --   horizontal = "Center",
  --   vertical = "Center",
  -- },
  window_close_confirmation = "NeverPrompt", -- AlwaysPrompt or NeverPrompt

  --pane
  inactive_pane_hsb = {
    saturation = 0.5,
    brightness = 1.0,
  },
  default_cursor_style = "SteadyBlock", -- BlinkingBlock, SteadyUnderline, BlinkingUnderline, SteadyBar, BlinkingBar
  hide_mouse_cursor_when_typing = true,

  -- command palette
  command_palette_font = wezterm.font("Roboto"),
  command_palette_bg_color = "#1d2230",
  command_palette_fg_color = "#769ff0",
  command_palette_rows = 18,
  command_palette_font_size = 14.0,

  -- char select
  char_select_font = wezterm.font("Roboto"),
  char_select_bg_color = "#1d2230",
  char_select_fg_color = "#769ff0",

  ----------------------------------------------------
  -- Tab
  ----------------------------------------------------
  show_tabs_in_tab_bar = true,
  hide_tab_bar_if_only_one_tab = false,
  tab_bar_at_bottom = true,
  show_new_tab_button_in_tab_bar = false,
  show_close_tab_button_in_tabs = false, -- Can only be used in nightly
  tab_max_width = 30,
  use_fancy_tab_bar = false,
  -- Hide borders between tabs
  colors = {
    tab_bar = {
      background = "none",
      inactive_tab_edge = "none",
    },
    cursor_bg = "#ffcc00", -- カーソルの背景色（ブロックカーソルの本体色）
    cursor_fg = "#000000", -- カーソル内の文字の色
    cursor_border = "#ffaa00", -- カーソルの枠線の色（主にブロックカーソルで使われる）
  },
}

function module.apply_to_config(config)
  for k, v in pairs(appearance) do
    config[k] = v
  end
end

return module
