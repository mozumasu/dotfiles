local wezterm = require("wezterm")
local act = wezterm.action

local module = {}

-- ワークスペースごとに、切り替え前にいたワークスペース名を保持する
local previous_workspaces = {}

-- 指定ワークスペースとの行き来をトグルするアクションを返す
local function toggle_workspace(name, spawn)
  return wezterm.action_callback(function(window, pane)
    local current = wezterm.mux.get_active_workspace()

    if current == name then
      local target = previous_workspaces[name] or "default"
      window:perform_action(act.SwitchToWorkspace({ name = target }), pane)
    else
      previous_workspaces[name] = current
      window:perform_action(act.SwitchToWorkspace({ name = name, spawn = spawn }), pane)
    end
  end)
end

local keys = {
  { key = "s", mods = "CTRL|CMD", action = toggle_workspace("scratch") },
  {
    key = "a",
    mods = "CTRL|CMD",
    action = toggle_workspace("nb", { cwd = wezterm.home_dir .. "/src/github.com/mozumasu/nb" }),
  },
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
