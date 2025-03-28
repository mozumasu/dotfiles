local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.set_environment_variables = {
  PATH = os.getenv("PATH"),
}
config.skip_close_confirmation_for_processes_named = {
  "man",
  "nvim",
  "bash",
  "zsh",
  "sh",
  "fzf",
}
config.launch_menu = {
  {
    label = "🗓 作業日報を書く",
    args = { os.getenv("SHELL"), "-l", "-c", "bash ~/dotfiles/.bin/gen_daily_report.sh" },
  },
}

config.automatically_reload_config = true
config.audible_bell = "Disabled"
-- 日本語を入力するのに必要
config.use_ime = true

local color = require("color")
local keymaps = require("keymaps")
local functions = require("functions")
local appearance = require("appearance")
local workspace = require("workspace")
color.apply_to_config(config)
keymaps.apply_to_config(config)
functions.apply_to_config(config)
appearance.apply_to_config(config)
workspace.apply_to_config(config)

return config
