local wezterm = require("wezterm")
local module = {}

function module.apply_to_config(config)
  local title_cache = {}
  local ssh_host_cache = {}
  local ssh_original_cmd_cache = {} -- Cache original command when connecting to ssh

  -- Icon
  local TAB_ICON_DOCKER = wezterm.nerdfonts.md_docker
  local TAB_ICON_PYTHON = wezterm.nerdfonts.dev_python
  local TAB_ICON_NEOVIM = wezterm.nerdfonts.linux_neovim
  local TAB_ICON_ZSH = wezterm.nerdfonts.dev_terminal
  local TAB_ICON_TASK = wezterm.nerdfonts.cod_server_process
  local TAB_ICON_NODE = wezterm.nerdfonts.md_language_typescript
  local TAB_ICON_NB = wezterm.nerdfonts.md_notebook
  local TAB_ICON_SSH = wezterm.nerdfonts.md_lan
  local TAB_ICON_FALLBACK = wezterm.nerdfonts.md_console_network

  -- Color
  local TAB_ICON_COLOR_DOCKER = "#4169e1"
  local TAB_ICON_COLOR_PYTHON = "#ffd700"
  local TAB_ICON_COLOR_NEOVIM = "#57A143"
  local TAB_ICON_COLOR_ZSH = "#769ff0"
  local TAB_ICON_COLOR_TASK = "#ff7f50"
  local TAB_ICON_COLOR_NODE = "#1e90ff"
  local TAB_ICON_COLOR_NB = "#9370DB"
  local TAB_ICON_COLOR_SSH = "#ff6b6b"
  local TAB_ICON_COLOR_FALLBACK = "#ae8b2d"
  local TAB_FOREGROUND_INACTIVE = "#a0a9cb"
  local TAB_BACKGROUND_INACTIVE = "#1d2230"
  local TAB_FOREGROUND_ACTIVE = "#313244"
  local TAB_BACKGROUND_ACTIVE = "#80EBDF"
  local TAB_BACKGROUND_SSH_ACTIVE = "#ff6b6b"
  local TAB_FOREGROUND_SSH_ACTIVE = "#ffffff"

  -- Decoration
  local SOLID_LEFT_CIRCLE = wezterm.nerdfonts.ple_left_half_circle_thick
  local SOLID_RIGHT_CIRCLE = wezterm.nerdfonts.ple_right_half_circle_thick

  local function basename(s)
    return string.gsub(s, "(.*[/\\])(.*)", "%2")
  end

  wezterm.on("pane-focus-changed", function(_, pane)
    local pane_id = pane:pane_id()
    local cmd = pane:get_foreground_process_name() or ""

    if cmd:find("ssh%s+") and not ssh_original_cmd_cache[pane_id] then
      ssh_original_cmd_cache[pane_id] = cmd
      local host = cmd:match("ssh%s+(__[%w_%-%.]+)")
      if not host then
        host = cmd:match("ssh%s+([%w_%-%.]+)")
      end
      if host then
        host = host:gsub("^__", "")
        ssh_host_cache[pane_id] = host
      end
    end
  end)

  wezterm.on("update-status", function(window, pane)
    local pane_id = pane:pane_id()

    local user_vars = pane.user_vars or {}
    if user_vars.ssh_host and user_vars.ssh_host ~= "" then
      -- Skip while ssh connecting
    else
      title_cache[pane_id] = "-"
      local cwd_url = pane:get_current_working_dir()
      if cwd_url then
        local cwd = cwd_url.file_path
        if cwd then
          local home = os.getenv("HOME")
          if home and cwd:find("^" .. home) then
            cwd = cwd:gsub("^" .. home, "~")
          end
          -- nbディレクトリの検出
          if cwd:find("%.nb") then
            title_cache[pane_id] = "nb"
          else
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
      end
    end

    -- Update the status bar at the same time
    local left_status = {}

    -- Get workspace name
    local workspace = window:active_workspace()
    wezterm.log_info("Current workspace: " .. tostring(workspace))
    table.insert(left_status, " " .. workspace .. " ")

    -- Check key table mode for workspace color
    local key_table = window:active_key_table()
    local workspace_color = "#80EBDF"  -- Default color (cyan)
    if key_table == "copy_mode" then
      workspace_color = "#ffd700"  -- Yellow for copy mode
    elseif key_table == "setting_mode" then
      workspace_color = "#39FF14"  -- Neon green for setting mode
    end

    -- Shown on the left
    window:set_left_status(wezterm.format({
      { Foreground = { Color = workspace_color } },
      { Text = " " .. table.concat(left_status, " | ") .. " " },
    }))
  end)

  wezterm.on("format-tab-title", function(tab, _, _, _, _, max_width)
    local pane = tab.active_pane
    local pane_id = pane.pane_id
    local process_name = basename(pane.foreground_process_name)

    local full_cmdline = pane.foreground_process_name or ""
    local title = pane.title or ""
    local user_vars = pane.user_vars or {}

    local is_ssh = false
    local ssh_host_from_uservar = user_vars.ssh_host
    if ssh_host_from_uservar and ssh_host_from_uservar ~= "" then
      is_ssh = true
      if not ssh_host_cache[pane_id] or ssh_host_cache[pane_id] ~= ssh_host_from_uservar then
        ssh_host_cache[pane_id] = ssh_host_from_uservar
      end
    elseif ssh_host_cache[pane_id] and (not ssh_host_from_uservar or ssh_host_from_uservar == "") then
      ssh_host_cache[pane_id] = nil
      ssh_original_cmd_cache[pane_id] = nil

      -- Retrieve directory information when ssh is finished
      local cwd_url = pane:get_current_working_dir()
      if cwd_url and cwd_url.file_path then
        local cwd = cwd_url.file_path
        local home = os.getenv("HOME")
        if home and cwd:find("^" .. home) then
          cwd = cwd:gsub("^" .. home, "~")
        end
        cwd = cwd:gsub("/$", "")
        local last_dir = cwd:match("([^/]+)$")
        title_cache[pane_id] = last_dir or cwd
      else
        title_cache[pane_id] = "-"
      end

      is_ssh = false
    elseif process_name:find("ssh") or full_cmdline:find("ssh") or process_name:find("multipass") then
      is_ssh = true

      if not ssh_host_cache[pane_id] then
        local host = full_cmdline:match("ssh%s+(__[%w_%-%.]+)")
        if not host then
          host = full_cmdline:match("ssh%s+([%w_%-%.]+)")
        end
        if host then
          host = host:gsub("^__", "")
          ssh_host_cache[pane_id] = host
        end
      end
    else
      if ssh_host_cache[pane_id] then
        ssh_host_cache[pane_id] = nil
        ssh_original_cmd_cache[pane_id] = nil
        title_cache[pane_id] = nil
      end
    end
    local background = TAB_BACKGROUND_INACTIVE
    local foreground = TAB_FOREGROUND_INACTIVE
    if tab.is_active and is_ssh then
      background = TAB_BACKGROUND_SSH_ACTIVE
      foreground = TAB_FOREGROUND_SSH_ACTIVE
    elseif tab.is_active then
      background = TAB_BACKGROUND_ACTIVE
      foreground = TAB_FOREGROUND_ACTIVE
    end
    local edge_background = TAB_BACKGROUND_INACTIVE -- Make it the same background color for the tab bar
    local edge_foreground = background

    local cwd = "-"
    if is_ssh then
      local cached_host = ssh_host_cache[pane_id]
      if cached_host then
        cwd = cached_host
      else
        cwd = "ssh"
      end
    elseif title_cache[pane_id] then
      cwd = title_cache[pane_id]
      local cmdline = pane.foreground_process_name or ""
      local current_cwd = title_cache[pane_id] or ""
      if
        cmdline:find("/nb")
        or cmdline:find("nb ")
        or process_name == "nb"
        or current_cwd:find("%.nb")
        or cwd == "nb"
      then
        cwd = "nb"
      end
    end

    local icon = TAB_ICON_FALLBACK
    local icon_foreground = TAB_ICON_COLOR_FALLBACK
    local cmdline = pane.foreground_process_name or ""
    local current_cwd = title_cache[pane_id] or ""
    if is_ssh then
      icon = TAB_ICON_SSH
      -- If the ssh tab is active, the icon is white, if inactive, the icon is red
      if tab.is_active then
        icon_foreground = "#ffffff"
      else
        icon_foreground = TAB_ICON_COLOR_SSH
      end
    elseif pane.title == "nvim" then
      icon = TAB_ICON_NEOVIM
      icon_foreground = TAB_ICON_COLOR_NEOVIM
    elseif
      cmdline:find("/nb")
      or cmdline:find("nb ")
      or process_name == "nb"
      or current_cwd:find("%.nb")
      or cwd == "nb"
    then
      icon = TAB_ICON_NB
      icon_foreground = TAB_ICON_COLOR_NB
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
    
    -- Add zoom indicator if the pane is zoomed
    local zoom_indicator = ""
    for _, pane_info in ipairs(tab.panes) do
      if pane_info.is_zoomed then
        zoom_indicator = wezterm.nerdfonts.md_magnify .. " "
        break
      end
    end
    
    return {
      { Background = { Color = edge_background } },
      { Text = " " },
      { Foreground = { Color = edge_foreground } },
      { Text = SOLID_LEFT_CIRCLE },
      { Background = { Color = background } },
      { Foreground = { Color = icon_foreground } },
      { Text = icon },
      { Background = { Color = background } },
      { Foreground = { Color = foreground } },
      { Text = zoom_indicator },
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
