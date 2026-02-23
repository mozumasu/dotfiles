local wezterm = require("wezterm")
local module = {}

local PID_FILE = "/tmp/.wezterm_caffeinate.pid"

-- caffeinateを停止
local function stop()
  local f = io.open(PID_FILE, "r")
  if not f then return end
  local pid = f:read("*l")
  f:close()
  if pid and pid ~= "" then
    os.execute("kill " .. pid .. " 2>/dev/null")
  end
  os.remove(PID_FILE)
end

-- caffeinateをバックグラウンドで開始してPIDを保存
local function start(duration_secs)
  stop()
  local cmd
  if duration_secs then
    cmd = string.format("sh -c 'caffeinate -d -t %d & echo $!'", duration_secs)
  else
    cmd = "sh -c 'caffeinate -d & echo $!'"
  end
  local handle = io.popen(cmd)
  if handle then
    local pid = handle:read("*l")
    handle:close()
    if pid and pid ~= "" then
      local f = io.open(PID_FILE, "w")
      if f then
        f:write(pid)
        f:close()
      end
    end
  end
end

-- caffeinateが実行中かチェック
local function is_running()
  local f = io.open(PID_FILE, "r")
  if not f then return false end
  local pid = f:read("*l")
  f:close()
  if not pid or pid == "" then return false end
  local result = os.execute("kill -0 " .. pid .. " 2>/dev/null")
  return result == true or result == 0
end

-- コマンドパレット用エントリを返す（Start/Stop を常に表示）
function module.get_commands()
  local running = is_running()
  local commands = {}

  local options = {
    { label = "Caffeinate: Start (無制限)", secs = nil },
    { label = "Caffeinate: Start 30 min",   secs = 1800 },
    { label = "Caffeinate: Start 1 hour",   secs = 3600 },
    { label = "Caffeinate: Start 2 hours",  secs = 7200 },
  }
  for _, opt in ipairs(options) do
    local secs = opt.secs
    table.insert(commands, {
      brief = opt.label,
      icon = "md_coffee",
      action = wezterm.action_callback(function(window, _)
        start(secs)
        local msg = secs
          and string.format("%d分間スリープを防止します。", secs / 60)
          or "スリープを無制限に防止します。"
        window:toast_notification("Caffeinate", msg, nil, 3000)
      end),
    })
  end

  -- Stop は常に表示（実行中なら [running] を付加）
  table.insert(commands, {
    brief = running and "Caffeinate: Stop [running]" or "Caffeinate: Stop",
    icon = "md_sleep",
    action = wezterm.action_callback(function(window, _)
      stop()
      window:toast_notification("Caffeinate", "停止しました。スリープが有効になります。", nil, 3000)
    end),
  })

  return commands
end

return module
