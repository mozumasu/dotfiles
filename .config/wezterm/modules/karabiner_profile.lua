local wezterm = require("wezterm")
local act = wezterm.action
local module = {}

-- karabiner_cliのパス
local KARABINER_CLI = "/opt/homebrew/bin/karabiner_cli"

-- シェル用のシングルクォートエスケープ
local function shell_escape(str)
  return "'" .. str:gsub("'", "'\\''") .. "'"
end

-- karabiner.jsonからプロファイル名一覧を取得
local function get_profiles()
  local config_path = os.getenv("HOME") .. "/.config/karabiner/karabiner.json"
  -- perlでprofilesセクション内のname要素を順に抽出
  local cmd = string.format(
    [[perl -0777 -e 'open(my $f,"<",$ARGV[0]) or die; local $/; my $json=<$f>; ($json)=$json=~/"profiles"\s*:\s*\[(.*)\]/s; while($json=~/"name"\s*:\s*"([^"]+)"/g){print "$1\n"}' %s 2>/dev/null]],
    shell_escape(config_path)
  )

  local handle = io.popen(cmd)
  if not handle then return {} end

  local result = handle:read("*a")
  handle:close()

  local profiles = {}
  for name in result:gmatch("[^\r\n]+") do
    if name ~= "" then
      table.insert(profiles, name)
    end
  end
  return profiles
end

-- プロファイルを切り替える
local function select_profile(name)
  local ok = os.execute(KARABINER_CLI .. " --select-profile " .. shell_escape(name))
  if ok then
    wezterm.log_info("Karabiner profile switched to: " .. name)
  else
    wezterm.log_error("Failed to switch Karabiner profile: " .. name)
  end
end

-- InputSelectorによるプロファイル選択アクション（キーバインド用）
local function create_profile_selector()
  return wezterm.action_callback(function(window, pane)
    local profiles = get_profiles()

    if #profiles == 0 then
      window:toast_notification(
        "Karabiner Profile",
        "No profiles found in ~/.config/karabiner/karabiner.json",
        nil,
        4000
      )
      return
    end

    local choices = {}
    for _, name in ipairs(profiles) do
      table.insert(choices, { label = name, id = name })
    end

    window:perform_action(
      act.InputSelector({
        title = "Select Karabiner Profile",
        choices = choices,
        fuzzy = true,
        action = wezterm.action_callback(function(_, _, id, _)
          if not id then return end
          select_profile(id)
        end),
      }),
      pane
    )
  end)
end

-- コマンドパレット用エントリを返す（keymaps.luaから呼び出す）
function module.get_commands()
  local profiles = get_profiles()
  local commands = {}

  for _, name in ipairs(profiles) do
    local profile_name = name
    table.insert(commands, {
      brief = "Karabiner: " .. profile_name,
      icon = "md_keyboard",
      action = wezterm.action_callback(function(_, _)
        select_profile(profile_name)
      end),
    })
  end

  return commands
end

-- キーバインドを追加（LEADER + k）
function module.apply_to_config(config)
  table.insert(config.keys, {
    key = "k",
    mods = "LEADER",
    action = create_profile_selector(),
  })
end

return module
