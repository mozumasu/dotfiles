local wezterm = require("wezterm")
local act = wezterm.action
local module = {}

-- Profile取得関数（aws CLI経由）
local function get_profiles_from_cli()
  local handle = io.popen("aws configure list-profiles 2>/dev/null")
  if not handle then return nil end

  local result = handle:read("*a")
  handle:close()

  if result == "" then return nil end

  local profiles = {}
  for profile in result:gmatch("[^\r\n]+") do
    if profile ~= "" then
      table.insert(profiles, profile)
    end
  end

  return #profiles > 0 and profiles or nil
end

-- Profile取得関数（設定ファイル直接パース）
local function get_profiles_from_config()
  local home = os.getenv("HOME")
  local config_file = home .. "/.aws/config"

  -- perlを使用してプロファイル名を抽出
  local cmd = string.format(
    "perl -ne 'print \"$1\\n\" if /^\\[profile (.+)\\]/' %s 2>/dev/null | sort -u",
    config_file
  )

  local handle = io.popen(cmd)
  if not handle then return nil end

  local result = handle:read("*a")
  handle:close()

  if result == "" then return nil end

  local profiles = {}
  for profile in result:gmatch("[^\r\n]+") do
    if profile ~= "" then
      table.insert(profiles, profile)
    end
  end

  return #profiles > 0 and profiles or nil
end

-- Profile取得のメイン関数
local function get_aws_profiles()
  local profiles = get_profiles_from_cli()
  if not profiles then
    profiles = get_profiles_from_config()
  end
  return profiles
end

-- InputSelectorアクション生成
local function create_aws_profile_selector()
  return wezterm.action_callback(function(window, pane)
    local profiles = get_aws_profiles()

    if not profiles or #profiles == 0 then
      window:toast_notification(
        "AWS Profile Selector",
        "No AWS profiles found. Please check ~/.aws/config",
        nil,
        4000
      )
      return
    end

    local choices = {}
    for _, profile in ipairs(profiles) do
      table.insert(choices, {
        label = profile,
        id = profile,
      })
    end

    window:perform_action(
      act.InputSelector({
        action = wezterm.action_callback(function(_, input_pane, id, label)
          if not id and not label then
            wezterm.log_info("AWS Profile selection cancelled")
          else
            wezterm.log_info("Selected AWS Profile: " .. id)
            -- export AWS_PROFILE=xxx 形式で入力
            input_pane:send_text("export AWS_PROFILE=" .. id)
          end
        end),
        title = "Select AWS Profile",
        choices = choices,
        fuzzy = true,
      }),
      pane
    )
  end)
end

-- configへの適用
function module.apply_to_config(config)
  table.insert(config.keys, {
    key = "p",
    mods = "LEADER",
    action = create_aws_profile_selector(),
  })
end

return module
