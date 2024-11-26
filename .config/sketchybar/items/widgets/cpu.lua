local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

-- Execute the event provider binary which provides the event "cpu_update" for
-- the cpu load data, which is fired every 2.0 seconds.
sbar.exec("killall cpu_load >/dev/null; $CONFIG_DIR/helpers/event_providers/cpu_load/bin/cpu_load cpu_update 1.0")

local cpu_graph = sbar.add("graph", "widgets.cpu.graph", 60, {
	position = "right",
	height = 27,
	graph = {
		color = colors.accent1,
		line_width = 1.0,
	},
	y_offset = 4,
	padding_right = 0,
	padding_left = -10,
})

local cpu = sbar.add("item", "widgets.cpu", {
	position = "right",
	background = {
		height = 22,
		color = { alpha = 0 },
		border_color = { alpha = 0 },
		drawing = true,
	},
	icon = {
		string = icons.cpu,
		color = colors.blue,
	},
	label = {
		string = "??%",
		color = colors.blue,
		font = {
			family = settings.font.numbers,
			-- style = settings.font.style_map["Bold"],
			-- size = 9.0,
		},
		align = "right",
	},
	padding_right = 0,
	padding_left = 5,
})

-- Background around the cpu item
local bracket = sbar.add("bracket", "widgets.cpu.bracket", { cpu_graph.name, cpu.name }, {
	background = { color = colors.tn_black3, border_color = colors.blue },
})

cpu_graph:subscribe("cpu_update", function(env)
	-- Also available: env.user_load, env.sys_load
	local load = tonumber(env.total_load)
	-- Due what height is not enabled to be set in the graph, divide the value by 150.0
	cpu_graph:push({ load / 150. })

	local alpha = 0.4
	local color = colors.tn_blue
	local fill_color = colors.with_alpha(color, alpha)
	if load > 30 then
		if load < 60 then
			color = colors.tn_yellow
			fill_color = colors.with_alpha(color, alpha)
		elseif load < 80 then
			color = colors.tn_orange
			fill_color = colors.with_alpha(color, alpha)
		else
			color = colors.tn_red
			fill_color = colors.with_alpha(color, alpha)
		end
	end

	cpu_graph:set({
		graph = { color = color, fill_color = fill_color },
	})

	cpu:set({
		label = {
			string = env.total_load .. "%",
			color = color,
		},
		icon = { color = color },
	})
	bracket:set({ background = { border_color = color } })
end)

cpu:subscribe("mouse.clicked", function(env)
	sbar.exec("open -a 'Activity Monitor'")
end)

-- Background around the cpu item
sbar.add("item", "widgets.cpu.padding", {
	position = "right",
	width = settings.group_paddings,
})
