local wezterm = require("wezterm")

local module = {}

function module.apply_to_config(config)
  -- Use the defaults as a base
  config.hyperlink_rules = wezterm.default_hyperlink_rules()
  
  -- GitHub repository format (owner/repo) - only in specific contexts
  -- Match GitHub URLs that are already partial (missing https://)
  table.insert(config.hyperlink_rules, {
    regex = [[github\.com/([\w\d-]+)/([\w\d.-]+)]],
    format = "https://github.com/$1/$2",
  })
  
  -- Match owner/repo when clearly mentioned (e.g., in quotes or after "clone")
  table.insert(config.hyperlink_rules, {
    regex = [["([\w\d-]+)/([\w\d.-]+)"]],
    format = "https://github.com/$1/$2",
  })
end

return module
