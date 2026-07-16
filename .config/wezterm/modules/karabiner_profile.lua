local wezterm = require("wezterm")
local util = require("modules.util")
local module = {}

-- karabiner_cliのパス
local KARABINER_CLI = "/opt/homebrew/bin/karabiner_cli"

-- karabiner.jsonからプロファイル名一覧を取得
local function get_profiles()
  local config_path = os.getenv("HOME") .. "/.config/karabiner/karabiner.json"
  -- perlでprofilesセクション内のname要素を順に抽出
  local cmd = string.format(
    [[perl -0777 -e 'open(my $f,"<",$ARGV[0]) or die; local $/; my $json=<$f>; ($json)=$json=~/"profiles"\s*:\s*\[(.*)\]/s; while($json=~/"name"\s*:\s*"([^"]+)"/g){print "$1\n"}' %s 2>/dev/null]],
    util.shell_escape(config_path)
  )
  return util.run_lines(cmd)
end

-- プロファイルを切り替える
local function select_profile(name)
  local ok = os.execute(KARABINER_CLI .. " --select-profile " .. util.shell_escape(name))
  if ok then
    wezterm.log_info("Karabiner profile switched to: " .. name)
  else
    wezterm.log_error("Failed to switch Karabiner profile: " .. name)
  end
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

return module
