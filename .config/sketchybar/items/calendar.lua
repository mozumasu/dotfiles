local settings = require("settings")
local colors = require("colors")

-- Padding item required because of bracket
-- sbar.add("item", { position = "right", width = settings.group_paddings })
local cal_clock = sbar.add("item", {
	icon = {
		drawing = "off",
	},
	label = {
		color = colors.tn_blue,
		padding_right = 0,
		align = "right",
		font = { family = settings.font.numbers },
		y_offset = 6,
	},
	position = "right",
	update_freq = 1,
	padding_left = -43,
	padding_right = 12,
})

local cal_day_of_week = sbar.add("item", {
	icon = {
		drawing = "off",
	},
	label = {
		color = colors.tn_blue,
		padding_right = 0,
		align = "center",
		font = { family = settings.font.numbers },
		y_offset = -6,
	},
	position = "right",
	update_freq = 1,
	padding_left = 0,
	padding_right = 0,
})

local cal_month = sbar.add("item", {
	icon = {
		drawing = "off",
	},
	label = {
		color = colors.tn_blue,
		padding_right = 0,
		align = "center",
		font = { family = settings.font.numbers },
		y_offset = 6,
		padding_left = 0,
	},
	position = "right",
	update_freq = 1,
	padding_left = -24,
	padding_right = 5,
})

local cal_day = sbar.add("item", {
	icon = {
		drawing = "off",
	},
	label = {
		color = colors.tn_blue,
		padding_right = 0,
		align = "center",
		font = { family = settings.font.numbers },
		y_offset = -6,
	},
	width = 32,
	position = "right",
	update_freq = 1,
	padding_left = 3,
	padding_right = 0,
})

-- Double border for calendar using a single item bracket
sbar.add("bracket", { cal_clock.name, cal_month.name, cal_day_of_week.name, cal_day.name }, {
	background = {
		color = colors.tn_black3,
		height = 34,
		border_color = colors.tn_blue,
	},
})

-- Padding item required because of bracket
sbar.add("item", { position = "right", width = settings.group_paddings })

cal_clock:subscribe({ "forced", "routine", "system_woke" }, function(env)
	cal_clock:set({ label = os.date("%H:%M") })
end)

cal_month:subscribe({ "forced", "routine", "system_woke" }, function(env)
	cal_month:set({ label = os.date("%b.") })
end)

cal_day_of_week:subscribe({ "forced", "routine", "system_woke" }, function(env)
	cal_day_of_week:set({ label = os.date("%a.") })
end)

cal_day:subscribe({ "forced", "routine", "system_woke" }, function(env)
	cal_day:set({ label = os.date("%d") })
end)

-- add width
sbar.add("item", { position = "right", width = 6 })
