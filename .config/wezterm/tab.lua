local wezterm = require("wezterm")
local module = {}

function module.apply_to_config(config)
  local title_cache = {}

  -- アイコン
  local TAB_ICON_DOCKER = wezterm.nerdfonts.md_docker
  local TAB_ICON_PYTHON = wezterm.nerdfonts.dev_python
  local TAB_ICON_NEOVIM = wezterm.nerdfonts.linux_neovim
  local TAB_ICON_ZSH = wezterm.nerdfonts.dev_terminal
  local TAB_ICON_TASK = wezterm.nerdfonts.cod_server_process
  local TAB_ICON_NODE = wezterm.nerdfonts.md_language_typescript
  local TAB_ICON_FALLBACK = wezterm.nerdfonts.md_console_network

  -- 色
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
  local TAB_BACKGROUND_SSH_ACTIVE = "#ff0000"

  -- デコレーション
  local SOLID_LEFT_CIRCLE = wezterm.nerdfonts.ple_left_half_circle_thick
  local SOLID_RIGHT_CIRCLE = wezterm.nerdfonts.ple_right_half_circle_thick

  local function basename(s)
    return string.gsub(s, "(.*[/\\])(.*)", "%2")
  end

  wezterm.on("update-status", function(window, pane)
    local pane_id = pane:pane_id()
    title_cache[pane_id] = "-"
    local cwd_url = pane:get_current_working_dir()
    if cwd_url then
      local cwd = cwd_url.file_path
      if cwd then
        local home = os.getenv("HOME")
        if home and cwd:find("^" .. home) then
          cwd = cwd:gsub("^" .. home, "~")
        end
        local github_prefix_pattern = ".*/src/github.com/([^/]+)/([^/]+)"
        local user, project = cwd:match(github_prefix_pattern)
        if user and project then
          title_cache[pane_id] = project
        else
          cwd = cwd:gsub("/$", "")
          local last_dir = cwd:match("([^/]+)$")
          title_cache[pane_id] = last_dir or cwd
        end
      end
    end

    -- Update the status bar at the same time
    local left_status = {}

    -- Get workspace name
    local workspace = window:active_workspace()
    wezterm.log_info("Current workspace: " .. tostring(workspace))
    table.insert(left_status, " " .. workspace .. " ")

    -- Shown on the left
    window:set_left_status(wezterm.format({
      { Foreground = { Color = "#80EBDF" } },
      { Text = " " .. table.concat(left_status, " | ") .. " " },
    }))
  end)

  wezterm.on("format-tab-title", function(tab, _, _, _, _, max_width)
    local pane = tab.active_pane
    local pane_id = pane.pane_id
    local process_name = basename(pane.foreground_process_name)
    local background = TAB_BACKGROUND_INACTIVE
    local foreground = TAB_FOREGROUND_INACTIVE
    if tab.is_active and (process_name:find("ssh") or process_name:find("multipass")) then
      background = TAB_BACKGROUND_SSH_ACTIVE
    elseif tab.is_active then
      background = TAB_BACKGROUND_ACTIVE
      foreground = TAB_FOREGROUND_ACTIVE
    end
    local edge_background = "none"
    local edge_foreground = background

    local cwd = "-"
    if title_cache[pane_id] then
      cwd = title_cache[pane_id]
      if process_name:find("ssh") or process_name:find("multipass") then
        local host = pane.title:match("@([%w%.-]+)")
        if host then
          cwd = host
        end
      end
    end

    local icon = TAB_ICON_FALLBACK
    local icon_foreground = TAB_ICON_COLOR_FALLBACK
    if pane.title == "nvim" then
      icon = TAB_ICON_NEOVIM
      icon_foreground = TAB_ICON_COLOR_NEOVIM
    elseif pane.title == "zsh" then
      icon = TAB_ICON_ZSH
      icon_foreground = TAB_ICON_COLOR_ZSH
    elseif pane.title == "Python" or string.find(pane.title, "python") then
      icon = TAB_ICON_PYTHON
      icon_foreground = TAB_ICON_COLOR_PYTHON
    elseif pane.title == "node" or string.find(pane.title, "node") then
      icon = TAB_ICON_NODE
      icon_foreground = TAB_ICON_COLOR_NODE
    elseif pane.title == "docker" or string.find(pane.title, "docker") then
      icon = TAB_ICON_DOCKER
      icon_foreground = TAB_ICON_COLOR_DOCKER
    elseif pane.title == "task" or string.find(pane.title, "task") then
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
      { Attribute = { Intensity = "Bold" } },
      { Text = title },
      { Background = { Color = edge_background } },
      { Foreground = { Color = edge_foreground } },
      { Text = SOLID_RIGHT_CIRCLE },
    }
  end)
end

return module
