local wezterm = require("wezterm")
local config = wezterm.config_builder()

local shell = os.getenv("SHELL")

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
    cwd = os.getenv("HOME") .. "/dotfiles",
    args = { shell, "-l", "-c", "bash .bin/gen_daily_report.sh" },
  },
  {
    label = "Show WezTerm Path",
    args = { shell, "-c", "echo $PATH && read" },
  },
}

config.automatically_reload_config = true
config.audible_bell = "Disabled"
-- 日本語を入力するのに必要
config.use_ime = true
-- Alt key behavior
config.send_composed_key_when_left_alt_is_pressed = false -- Treat left Alt as Meta key (sends escape sequences)
config.send_composed_key_when_right_alt_is_pressed = true -- Keep right Alt for key composition
-- https://github.com/mtgto/macSKK?tab=readme-ov-file#q-wezterm-%E3%81%A7-c-j-%E3%82%92%E6%8A%BC%E3%81%99%E3%81%A8%E6%94%B9%E8%A1%8C%E3%81%95%E3%82%8C%E3%81%A6%E3%81%97%E3%81%BE%E3%81%84%E3%81%BE%E3%81%99
config.macos_forward_to_ime_modifier_mask = "SHIFT|CTRL"

local color = require("color")
local keymaps = require("keymaps")
local functions = require("functions")
local appearance = require("appearance")
local workspace = require("workspace")
local hyperlinks = require("hyperlinks")
local tab = require("tab")
local quick_select = require("quick_select")
color.apply_to_config(config)
keymaps.apply_to_config(config)
functions.apply_to_config(config)
appearance.apply_to_config(config)
workspace.apply_to_config(config)
hyperlinks.apply_to_config(config)
tab.apply_to_config(config)
quick_select.apply_to_config(config)

return config
