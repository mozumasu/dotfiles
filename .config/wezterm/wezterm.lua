local wezterm = require("wezterm")
local config = wezterm.config_builder()
local mux = wezterm.mux

config.automatically_reload_config = true
config.font_size = 13.0
config.use_ime = true
config.window_background_opacity = 0.7
config.macos_window_background_blur = 13
config.audible_bell = "Disabled"
config.font = wezterm.font("HackGen Console NF")

----------------------------------------------------
-- Pane
----------------------------------------------------
config.inactive_pane_hsb = {
  saturation = 1.0,
  brightness = 0.5,
}

----------------------------------------------------
-- Title Bar
----------------------------------------------------
-- Title bar not listed
config.window_decorations = "RESIZE"

----------------------------------------------------
-- Tab
----------------------------------------------------
-- Display tabs
config.show_tabs_in_tab_bar = true
-- If there is one tab, it is not displayed
config.hide_tab_bar_if_only_one_tab = true
-- Hide borders between tabs
config.colors = {
  tab_bar = {
    background = "none",
    inactive_tab_edge = "none",
  },
}
config.show_new_tab_button_in_tab_bar = false
-- Can only be used in nightly
config.show_close_tab_button_in_tabs = false
config.tab_max_width = 30
-- Adjust the tab bar to the background color
config.window_background_gradient = {
  colors = { "#000000" },
}

----------------------------------------------------
-- Fansy Tab Bar (now, not use)
----------------------------------------------------
config.use_fancy_tab_bar = false
-- Transparent tab bar
config.window_frame = {
  inactive_titlebar_bg = "none",
  active_titlebar_bg = "none",
}

----------------------------------------------------
-- 各タブの「ディレクトリ名」を記憶しておくテーブル
local title_cache = {}

wezterm.on("update-status", function(window, pane)
  local pane_id = pane:pane_id()
  title_cache[pane_id] = "-" -- default value

  local cwd_url = pane:get_current_working_dir()

  if cwd_url then
    local cwd = cwd_url.path
    if cwd then
      local home = os.getenv("HOME")
      if home and cwd:find("^" .. home) then
        cwd = cwd:gsub("^" .. home, "~")
      end

      -- Check if it follows the format /src/github.com/{user}/{project}/...
      local github_prefix_pattern = ".*/src/github.com/([^/]+)/([^/]+)"
      local user, project = cwd:match(github_prefix_pattern)

      if user and project then
        title_cache[pane_id] = project
      else
        -- Extract only the directory name
        cwd = cwd:gsub("/$", "")
        local last_dir = cwd:match("([^/]+)$")
        title_cache[pane_id] = last_dir or cwd
      end
    end
  end
end)
-- TAB ICONS
local TAB_ICON_DOCKER = wezterm.nerdfonts.md_docker
local TAB_ICON_PYTHON = wezterm.nerdfonts.dev_python
local TAB_ICON_NEOVIM = wezterm.nerdfonts.linux_neovim
local TAB_ICON_ZSH = wezterm.nerdfonts.dev_terminal
local TAB_ICON_TASK = wezterm.nerdfonts.cod_server_process
local TAB_ICON_NODE = wezterm.nerdfonts.md_language_typescript
local TAB_ICON_FALLBACK = wezterm.nerdfonts.md_console_network
-- TAB COLORE
local TAB_ICON_COLOR_DOCKER = "#4169e1"
local TAB_ICON_COLOR_PYTHON = "#ffd700"
local TAB_ICON_COLOR_NEOVIM = "#57A143"
local TAB_ICON_COLOR_ZSH = "#769ff0"
local TAB_ICON_COLOR_TASK = "#ff7f50"
local TAB_ICON_COLOR_NODE = "#1e90ff"
local TAB_ICON_COLOR_FALLBACK = "#ae8b2d"
local TAB_FOREGROUND_INACTIVE = "#a0a9cb"
local TAB_BACKGROUND_INACTIVE = "#1d2230"
local TAB_FOREGROUND_ACTIVE = "#313244"
local TAB_BACKGROUND_ACTIVE = "#80EBDF"
-- Tab fitting
local SOLID_LEFT_CIRCLE = wezterm.nerdfonts.ple_left_half_circle_thick
local SOLID_RIGHT_CIRCLE = wezterm.nerdfonts.ple_right_half_circle_thick
-- local SOLID_LEFT_ARROW = wezterm.nerdfonts.ple_lower_right_triangle
-- local SOLID_RIGHT_ARROW = wezterm.nerdfonts.ple_upper_left_triangle
function basename(s)
  return string.gsub(s, "(.*[/\\])(.*)", "%2")
end

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local background = TAB_BACKGROUND_INACTIVE
  local foreground = TAB_FOREGROUND_INACTIVE
  if tab.is_active then
    background = TAB_BACKGROUND_ACTIVE
    foreground = TAB_FOREGROUND_ACTIVE
  end
  local edge_background = "none"
  local edge_foreground = background

  local pane = tab.active_pane
  local pane_id = pane.pane_id
  local process_name = basename(pane.foreground_process_name)

  local cwd = "none"
  if title_cache[pane_id] then
    cwd = title_cache[pane_id]
    if process_name:find("ssh") or process_name:find("multipass") then
      local host = pane.title:match("@([%w%.-]+)")
      if host then
        cwd = host
      end
    end
  else
    cwd = "-"
  end

  local icon = TAB_ICON_FALLBACK
  local icon_foreground = TAB_ICON_COLOR_FALLBACK
  if tab.active_pane.title == "nvim" then
    icon = TAB_ICON_NEOVIM
    icon_foreground = TAB_ICON_COLOR_NEOVIM
  elseif tab.active_pane.title == "zsh" then
    icon = TAB_ICON_ZSH
    icon_foreground = TAB_ICON_COLOR_ZSH
  elseif tab.active_pane.title == "Python" or string.find(tab.active_pane.title, "python") then
    icon = TAB_ICON_PYTHON
    icon_foreground = TAB_ICON_COLOR_PYTHON
  elseif tab.active_pane.title == "node" or string.find(tab.active_pane.title, "node") then
    icon = TAB_ICON_NODE
    icon_foreground = TAB_ICON_COLOR_NODE
  elseif tab.active_pane.title == "docker" or string.find(tab.active_pane.title, "docker") then
    icon = TAB_ICON_DOCKER
    icon_foreground = TAB_ICON_COLOR_DOCKER
  elseif tab.active_pane.title == "task" or string.find(tab.active_pane.title, "task") then
    icon = TAB_ICON_TASK
    icon_foreground = TAB_ICON_COLOR_TASK
  end

  local title = " " .. wezterm.truncate_right(cwd, max_width) .. " "
  return {
    { Background = { Color = edge_background } },
    { Text = " " },
    { Foreground = { Color = edge_foreground } },
    { Text = SOLID_LEFT_CIRCLE },
    { Background = { Color = edge_foreground } },
    { Foreground = { Color = icon_foreground } },
    { Text = icon },
    { Background = { Color = background } },
    { Foreground = { Color = foreground } },
    { Text = title },
    { Background = { Color = edge_background } },
    { Foreground = { Color = edge_foreground } },
    { Text = SOLID_RIGHT_CIRCLE },
  }
end)

----------------------------------------------------
-- keybinds
----------------------------------------------------
-- local act = require("wezterm").action

config.disable_default_key_bindings = true
config.keys = require("keybinds").keys
config.key_tables = require("keybinds").key_tables
config.leader = { key = "q", mods = "CTRL", timeout_milliseconds = 2000 }

-- config.keys = {
--   {
--     mods = "LEADER",
--     key = "s",
--     action = act.ShowLauncherArgs({ flags = "WORKSPACES", title = "Select workspace" }),
--   },
-- }

config.mouse_bindings = {
  {
    event = { Down = { streak = 3, button = "Left" } },
    action = wezterm.action.SelectTextAtMouseCursor("SemanticZone"),
    mods = "NONE",
  },
}

return config
