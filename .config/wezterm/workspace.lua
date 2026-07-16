local wezterm = require("wezterm")
local act = wezterm.action

local module = {}

-- Store the workspace we came from before switching to scratch/nb
local previous_workspace = nil
local previous_workspace_nb = nil

-- Toggle scratch workspace
local function toggle_scratch_workspace()
  return wezterm.action_callback(function(window, pane)
    local current = wezterm.mux.get_active_workspace()

    if current == "scratch" then
      -- If in scratch, go back to previous workspace or default
      local target = previous_workspace or "default"
      window:perform_action(act.SwitchToWorkspace({ name = target }), pane)
    else
      -- Store current workspace and switch to scratch
      previous_workspace = current
      window:perform_action(act.SwitchToWorkspace({ name = "scratch" }), pane)
    end
  end)
end

-- Toggle nb workspace
local function toggle_nb_workspace()
  return wezterm.action_callback(function(window, pane)
    local current = wezterm.mux.get_active_workspace()

    if current == "nb" then
      -- If in nb, go back to previous workspace or default
      local target = previous_workspace_nb or "default"
      window:perform_action(act.SwitchToWorkspace({ name = target }), pane)
    else
      -- Store current workspace and switch to nb
      previous_workspace_nb = current
      window:perform_action(
        act.SwitchToWorkspace({
          name = "nb",
          spawn = {
            cwd = wezterm.home_dir .. "/src/github.com/mozumasu/nb",
          },
        }),
        pane
      )
    end
  end)
end

local keys = {
  -- Toggle scratch workspace with CTRL+CMD+s
  { key = "s", mods = "CTRL|CMD", action = toggle_scratch_workspace() },
  -- Toggle nb workspace with CTRL+CMD+a
  { key = "a", mods = "CTRL|CMD", action = toggle_nb_workspace() },
  -- cmd+ctrl+n/p は herdr のワークスペース切り替えに使うため WezTerm ではバインドしない
  -- (kitty protocol 経由で herdr に届く)
}

function module.apply_to_config(config)
  config.keys = config.keys or {}
  for _, key in ipairs(keys) do
    table.insert(config.keys, key)
  end
end

return module
