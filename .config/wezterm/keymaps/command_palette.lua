local wezterm = require("wezterm")
local act = wezterm.action
local overlay = require("keymaps.overlay")

local module = {}

-- augment-command-palette イベントでコマンドパレットにカスタムアクションを追加
function module.setup()
  wezterm.on("augment-command-palette", function(_, _)
    local karabiner = require("modules.karabiner_profile")
    local caffeinate = require("modules.caffeinate")

    local commands = {
      {
        brief = "Launch: zsh",
        icon = "md_terminal",
        action = overlay.spawn_overlay_pane("zsh"),
      },
      {
        brief = "Launch: Ghost",
        icon = "md_ghost",
        action = overlay.spawn_overlay_pane("ghost"),
      },
      {
        brief = "Launch: Yazi",
        icon = "md_folder",
        action = overlay.spawn_overlay_pane("yazi"),
      },
      {
        brief = "Launch: Claude Code",
        icon = "md_robot",
        action = overlay.spawn_overlay_pane("claude"),
      },
      {
        brief = "GitHub: Browse (gh browse)",
        icon = "md_github",
        action = overlay.spawn_overlay_pane("gh browse"),
      },
      {
        brief = "Edit: ~/.aws/config",
        icon = "md_aws",
        action = overlay.spawn_overlay_pane("nvim ~/.aws/config"),
      },
      {
        brief = "Edit: ~/.ssh/conf.d/hosts/",
        icon = "md_server",
        action = overlay.spawn_overlay_pane("nvim ~/.ssh/conf.d/hosts/"),
      },
      {
        brief = "Edit: ~/.config/gcloud/configurations/",
        icon = "md_cloud",
        action = overlay.spawn_overlay_pane("nvim ~/.config/gcloud/configurations/"),
      },
      {
        brief = "VPN: Connect (vpnc)",
        icon = "md_vpn",
        action = overlay.spawn_overlay_pane("vpn-connect-with-fzf", true),
      },
      {
        brief = "Layout: vde-layout demo (current tab)",
        icon = "md_view_column",
        action = wezterm.action_callback(function(_, pane)
          local pane_id = pane:pane_id()
          wezterm.background_child_process({
            os.getenv("SHELL") or "/bin/zsh",
            "-lic",
            string.format("WEZTERM_PANE=%d vde-layout demo --current-window", pane_id),
          })
        end),
      },
      {
        brief = "Layout: vde-layout demo (new tab)",
        icon = "md_view_column",
        action = wezterm.action_callback(function(_, pane)
          local cwd = pane:get_current_working_dir()
          local cwd_path = cwd and cwd.file_path or os.getenv("HOME")
          wezterm.background_child_process({
            os.getenv("SHELL") or "/bin/zsh",
            "-lic",
            string.format("cd %q && vde-layout demo --new-window", cwd_path),
          })
        end),
      },
      {
        brief = "Herdr: Reload config",
        icon = "md_refresh",
        action = wezterm.action_callback(function(_, _)
          wezterm.background_child_process({
            os.getenv("SHELL") or "/bin/zsh",
            "-lic",
            "herdr server reload-config",
          })
        end),
      },
      {
        brief = "Herdr: New workspace",
        icon = "md_plus_box",
        action = wezterm.action_callback(function(window, pane)
          window:perform_action(
            act.PromptInputLine({
              description = "(herdr) New workspace name (empty for generated name):",
              action = wezterm.action_callback(function(_, _, line)
                if line == nil then
                  return
                end
                local cmd = "herdr workspace create --focus"
                if line ~= "" then
                  cmd = cmd .. " --label '" .. line:gsub("'", [['\'']]) .. "'"
                end
                wezterm.background_child_process({
                  os.getenv("SHELL") or "/bin/zsh",
                  "-lic",
                  cmd,
                })
              end),
            }),
            pane
          )
        end),
      },
      {
        brief = "AeroSpace: Reload config",
        icon = "md_refresh",
        action = wezterm.action_callback(function(_, _)
          wezterm.background_child_process({
            os.getenv("SHELL") or "/bin/zsh",
            "-lic",
            "aerospace reload-config",
          })
        end),
      },
      {
        brief = "Weather: wttr.in",
        icon = "md_weather_cloudy",
        action = overlay.spawn_overlay_pane("curl wttr.in | less -R"),
      },
    }

    -- Karabinerプロファイルエントリを追加
    for _, cmd in ipairs(karabiner.get_commands()) do
      table.insert(commands, cmd)
    end

    -- Caffeinateエントリを追加
    for _, cmd in ipairs(caffeinate.get_commands()) do
      table.insert(commands, cmd)
    end

    return commands
  end)
end

return module
