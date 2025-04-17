local wezterm = require("wezterm")

local module = {}

function module.apply_to_config(config)
  -- Use the defaults as a base
  config.hyperlink_rules = wezterm.default_hyperlink_rules()
  -- make task numbers clickable
  -- the first matched regex group is captured in $1.
  table.insert(config.hyperlink_rules, {
    regex = [[\b[tt](\d+)\b]],
    format = "https://example.com/tasks/?t=$1",
  })

  table.insert(config.hyperlink_rules, {
    regex = [[["]?([\w\d]{1}[-\w\d]+)(/){1}([-\w\d\.]+)["]?]],
    format = "https://www.github.com/$1/$3",
  })
end

return module
