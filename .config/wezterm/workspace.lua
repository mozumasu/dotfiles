local wezterm = require("wezterm")
local act = wezterm.action

local module = {}

local function kill_workspace(workspace)
  return function(_, _, _)
    workspace = workspace or wezterm.mux.get_active_workspace()

    local success, stdout = wezterm.run_child_process({
      "wezterm",
      "cli",
      "list",
      "--format=json",
    })

    if not success then
      return
    end

    local json = wezterm.json_parse(stdout)
    if not json then
      return
    end

    -- フィルタ関数定義（共通で使いたいなら別モジュール化してもOK）
    local function filter(tbl, predicate)
      local result = {}
      for _, v in ipairs(tbl) do
        if predicate(v) then
          table.insert(result, v)
        end
      end
      return result
    end

    local workspace_panes = filter(json, function(p)
      return p.workspace == workspace
    end)

    for _, p in ipairs(workspace_panes) do
      wezterm.run_child_process({
        "wezterm",
        "cli",
        "kill-pane",
        "--pane-id=" .. p.pane_id,
      })
      wezterm.log_info("kill-pane", p.pane_id, success)
    end
  end
end

local keys = {
  -- custom mode
  -- { key = "s", mods = "LEADER", action = act.ActivateKeyTable({ name = "config_mode", one_shot = false }) },
  {
    mods = "LEADER",
    key = "s",
    action = wezterm.action_callback(function(win, pane)
      -- 現在のPaneでworkspace_modeを有効化
      win:perform_action(act.ActivateKeyTable({ name = "workspace_mode", one_shot = false }), pane)
      -- workspace のリストを作成
      local workspaces = {}
      for i, name in ipairs(wezterm.mux.get_workspace_names()) do
        table.insert(workspaces, {
          id = name,
          label = string.format("%d. %s", i, name),
        })
      end
      local current = wezterm.mux.get_active_workspace()
      -- 選択メニューを起動
      win:perform_action(
        act.InputSelector({
          action = wezterm.action_callback(function(_, _, id, label)
            if not id and not label then
              wezterm.log_info("Workspace selection canceled") -- 入力が空ならキャンセル
            else
              win:perform_action(act.SwitchToWorkspace({ name = id }), pane) -- workspace を移動
            end
          end),
          title = "Select workspace",
          choices = workspaces,
          fuzzy = true,
          -- fuzzy_description = string.format("Select workspace: %s -> ", current), -- requires nightly build
        }),
        pane
      )
    end),
  },
}

local key_tables = {
  workspace_mode = {
    {
      -- Create new workspace
      mods = "SHIFT",
      key = "c",
      action = act.PromptInputLine({
        description = "(wezterm) Create new workspace:",
        action = wezterm.action_callback(function(window, _, line)
          -- canceled
          if not line then
            return
          end

          local tab = window:mux_window():active_tab()
          local pane = tab and tab:active_pane()

          if not pane then
            wezterm.log_error("No active pane")
            return
          end

          window:perform_action(
            act.SwitchToWorkspace({
              name = line,
            }),
            pane
          )
        end),
      }),
    },
    -- {
    --   key = "d",
    --   mods = "SHIFT",
    --   action = wezterm.action_callback(kill_workspace()),
    -- },
    { key = "Escape", action = "PopKeyTable" },
  },
}

function module.apply_to_config(config)
  for _, key in ipairs(keys) do
    table.insert(config.keys, key)
  end
  config.key_tables = config.key_tables or {}
  for name, table_def in pairs(key_tables) do
    config.key_tables[name] = table_def
  end
end

return module
