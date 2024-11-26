local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

-- Execute the event provider binary which provides the event "network_update"
-- for the network interface "en0", which is fired every 2.0 seconds.
sbar.exec(
	"killall network_load >/dev/null; $CONFIG_DIR/helpers/event_providers/network_load/bin/network_load en0 network_update 1.0"
)

local popup_width = 250

local wifi_up_graph = sbar.add("graph", "widgets.wifi1_graph", 42, {
	position = "right",
	align = "right",
	graph = {
		color = colors.tn_red,
		fill_color = colors.tn_red,
		fill = true,
		height = 17,
		line_width = 1,
		padding_left = 0,
		padding_right = 0,
	},
	padding_left = -64.5,
	padding_right = 0,
	y_offset = 21,
})

local wifi_down_graph = sbar.add("graph", "widgets.wifi2_graph", 42, {
	position = "right",
	graph = {
		color = colors.tn_cyan,
		fill_color = colors.tn_cyan,
		fill = true,
		height = 17,
		line_width = 1,
		padding_left = 0,
		padding_right = 0,
	},
	height = 17,
	padding_left = -20,
	padding_right = 0,
	y_offset = 9,
})

local wifi_up = sbar.add("item", "widgets.wifi1", {
	position = "right",
	padding_left = -8,
	width = 0,
	icon = {
		padding_right = 0,
		font = {
			style = settings.font.style_map["Bold"],
			size = 9.0,
		},
		string = icons.wifi.upload,
	},
	label = {
		font = {
			family = settings.font.numbers,
			style = settings.font.style_map["Bold"],
			size = 9.0,
		},
		color = colors.tn_red,
		string = "??? Bps",
	},
	y_offset = 6,
})

local wifi_down = sbar.add("item", "widgets.wifi2", {
	position = "right",
	padding_left = -5,
	icon = {
		padding_right = 0,
		font = {
			style = settings.font.style_map["Bold"],
			size = 9.0,
		},
		string = icons.wifi.download,
	},
	label = {
		font = {
			family = settings.font.numbers,
			style = settings.font.style_map["Bold"],
			size = 9.0,
		},
		color = colors.tn_cyan,
		string = "??? Bps",
	},
	y_offset = -6,
})

local wifi = sbar.add("item", "widgets.wifi.padding", {
	position = "right",
	label = { drawing = false },
	padding_right = 2,
	padding_left = 4,
})

-- Background around the item
local wifi_bracket = sbar.add("bracket", "widgets.wifi.bracket", {
	wifi.name,
	wifi_up_graph.name,
	wifi_up.name,
	wifi_down_graph.name,
	wifi_down.name,
}, {
	background = { color = colors.tn_black3, border_color = colors.tn_magenta, border_width = 2 },
	popup = {
		align = "center",
		height = 30,
		background = { color = colors.tn_black3, border_color = colors.tn_magenta, border_width = 2 },
	},
})

local ssid = sbar.add("item", {
	position = "popup." .. wifi_bracket.name,
	icon = {
		font = {
			size = 13.0,
			style = settings.font.style_map["Bold"],
		},
		string = icons.wifi.router,
		color = colors.tn_magenta,
	},
	width = popup_width,
	align = "center",
	label = {
		font = {
			style = settings.font.style_map["Bold"],
		},
		max_chars = 18,
		string = "????????????",
		color = colors.tn_magenta,
	},
	background = {
		height = 2,
		color = colors.grey,
		y_offset = -15,
		border_color = colors.tn_magenta,
	},
})

local hostname = sbar.add("item", {
	position = "popup." .. wifi_bracket.name,
	icon = {
		font = {
			size = 13.0,
		},
		align = "left",
		string = "Hostname:",
		width = popup_width / 2,
		color = colors.tn_magenta,
	},
	label = {
		max_chars = 20,
		string = "????????????",
		width = popup_width / 2,
		align = "right",
		color = colors.tn_magenta,
	},
})

local ip = sbar.add("item", {
	position = "popup." .. wifi_bracket.name,
	icon = {
		font = {
			size = 13.0,
		},
		align = "left",
		string = "IP:",
		width = popup_width / 2,
		color = colors.tn_magenta,
	},
	label = {
		string = "???.???.???.???",
		width = popup_width / 2,
		align = "right",
		color = colors.tn_magenta,
	},
})

local mask = sbar.add("item", {
	position = "popup." .. wifi_bracket.name,
	icon = {
		font = {
			size = 13.0,
		},
		align = "left",
		string = "Subnet mask:",
		width = popup_width / 2,
		color = colors.tn_magenta,
	},
	label = {
		string = "???.???.???.???",
		width = popup_width / 2,
		align = "right",
		color = colors.tn_magenta,
	},
})

local router = sbar.add("item", {
	position = "popup." .. wifi_bracket.name,
	icon = {
		font = {
			size = 13.0,
		},
		align = "left",
		string = "Router:",
		width = popup_width / 2,
		color = colors.tn_magenta,
	},
	label = {
		string = "???.???.???.???",
		width = popup_width / 2,
		align = "right",
		color = colors.tn_magenta,
	},
})

wifi_up:subscribe("network_update", function(env)
	-- Extract the value and unit
	local upload_value, upload_unit = env.upload:match("^(%d+)%s*([KMG]?)")
	local download_value, download_unit = env.download:match("^(%d+)%s*([KMG]?)")

	-- Convert the value to a number
	upload_value = tonumber(upload_value)
	download_value = tonumber(download_value)

	-- Convert the value based on the unit (K=1024, M=1024^2, G=1024^3)
	local unit_multiplier = { K = 1024, M = 1024 ^ 2, G = 1024 ^ 3 }
	if upload_unit and unit_multiplier[upload_unit] then
		upload_value = upload_value * unit_multiplier[upload_unit]
	end
	if download_unit and unit_multiplier[download_unit] then
		download_value = download_value * unit_multiplier[download_unit]
	end

	-- Set the color
	local up_color = (upload_value == 0) and colors.tn_black1 or colors.tn_red
	local down_color = (download_value == 0) and colors.tn_black1 or colors.tn_cyan

	-- Add data to the graph
	wifi_up_graph:push({ upload_value / (2 * 100 * 1024 ^ 2) })
	wifi_down_graph:push({ download_value / (2 * 100 * 1024 ^ 2) })

	-- Set the label
	wifi_up:set({
		icon = { color = up_color },
		label = {
			string = env.upload,
			color = up_color,
		},
	})
	wifi_down:set({
		icon = { color = down_color },
		label = {
			string = env.download,
			color = down_color,
		},
	})
end)

wifi:subscribe({ "wifi_change", "system_woke" }, function(env)
	sbar.exec("ipconfig getifaddr en0", function(ip)
		local connected = not (ip == "")
		wifi:set({
			icon = {
				string = connected and icons.wifi.connected or icons.wifi.disconnected,
				color = connected and colors.tn_magenta or colors.tn_black1,
			},
		})
	end)
end)

local function hide_details()
	wifi_bracket:set({ popup = { drawing = false } })
end

local function toggle_details()
	local should_draw = wifi_bracket:query().popup.drawing == "off"
	if should_draw then
		wifi_bracket:set({ popup = { drawing = true } })
		sbar.exec("networksetup -getcomputername", function(result)
			hostname:set({ label = result })
		end)
		sbar.exec("ipconfig getifaddr en0", function(result)
			ip:set({ label = result })
		end)
		sbar.exec("ipconfig getsummary en0 | awk -F ' SSID : '  '/ SSID : / {print $2}'", function(result)
			ssid:set({ label = result })
		end)
		sbar.exec("networksetup -getinfo Wi-Fi | awk -F 'Subnet mask: ' '/^Subnet mask: / {print $2}'", function(result)
			mask:set({ label = result })
		end)
		sbar.exec("networksetup -getinfo Wi-Fi | awk -F 'Router: ' '/^Router: / {print $2}'", function(result)
			router:set({ label = result })
		end)
	else
		hide_details()
	end
end

wifi_up:subscribe("mouse.clicked", toggle_details)
wifi_down:subscribe("mouse.clicked", toggle_details)
wifi:subscribe("mouse.clicked", toggle_details)
wifi:subscribe("mouse.exited.global", hide_details)

local function copy_label_to_clipboard(env)
	local label = sbar.query(env.NAME).label.value
	sbar.exec('echo "' .. label .. '" | pbcopy')
	sbar.set(env.NAME, { label = { string = icons.clipboard, align = "center" } })
	sbar.delay(1, function()
		sbar.set(env.NAME, { label = { string = label, align = "right" } })
	end)
end

ssid:subscribe("mouse.clicked", copy_label_to_clipboard)
hostname:subscribe("mouse.clicked", copy_label_to_clipboard)
ip:subscribe("mouse.clicked", copy_label_to_clipboard)
mask:subscribe("mouse.clicked", copy_label_to_clipboard)
router:subscribe("mouse.clicked", copy_label_to_clipboard)

sbar.add("item", { position = "right", width = 6 })
