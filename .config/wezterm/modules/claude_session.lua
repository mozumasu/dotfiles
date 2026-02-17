local wezterm = require("wezterm")
local act = wezterm.action
local module = {}

-- configへの適用
function module.apply_to_config(config)
  wezterm.log_info("claude_session module loaded")
end

return module
