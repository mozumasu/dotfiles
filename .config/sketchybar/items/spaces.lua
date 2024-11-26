local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local app_icons = require("helpers.icon_map")

local spaces = {}

-- local colors_spaces = {
-- 	[1] = colors.yellow,
-- 	[2] = colors.cyan,
-- 	[3] = colors.magenta,
-- 	[4] = colors.white,
-- 	[5] = colors.blue,
-- 	[6] = colors.red,
-- 	[7] = colors.green,
-- 	[8] = colors.white,
-- 	[9] = colors.yellow,
-- 	[10] = colors.cyan,
-- }

local colors_spaces = {
	[1] = colors.cmap_1,
	[2] = colors.cmap_2,
	[3] = colors.cmap_3,
	[4] = colors.cmap_4,
	[5] = colors.cmap_5,
	[6] = colors.cmap_6,
	[7] = colors.cmap_7,
	[8] = colors.cmap_8,
	[9] = colors.cmap_9,
	[10] = colors.cmap_10,
}

for i = 1, 10, 1 do
	local space = sbar.add("space", "space." .. i, {

		space = i,
		icon = {
			font = {
				family = settings.font.numbers,
				size = 14,
			},
			string = i,
			padding_left = 5,
			padding_right = 0,
			color = colors_spaces[i],
			highlight_color = colors.tn_black3,
		},
		label = {
			padding_right = 10,
			padding_left = 3,
			color = colors_spaces[i],
			font = "sketchybar-app-font-bg:Regular:21.0",
			y_offset = -2,
		},
		padding_right = 4,
		padding_left = 4,
		background = {
			color = colors.transparent,
			height = 22,
			border_width = 0,
			border_color = colors.transparent,
		},
		popup = { background = { border_width = 5, border_color = colors.black } },
	})

	spaces[i] = space

	-- Single item bracket for space items to achieve double border on highlight
	-- local space_bracket = sbar.add("bracket", { space.name }, {
	-- 	background = {
	-- 		color = colors.transparent,
	-- 		border_color = colors.bg2,
	-- 		height = 28,
	-- 		border_width = 2,
	-- 	},
	-- })

	-- Padding space
	sbar.add("space", "space.padding." .. i, {
		space = i,
		script = "",
		width = settings.group_paddings,
	})

	local space_popup = sbar.add("item", {
		position = "popup." .. space.name,
		padding_left = 0,
		padding_right = 0,
		background = {
			drawing = true,
			image = {
				corner_radius = 6,
				scale = 0.2,
			},
		},
	})

	space:subscribe("space_change", function(env)
		local selected = env.SELECTED == "true"
		local color = selected and colors.grey or colors.bg2
		space:set({
			icon = { highlight = selected },
			label = { highlight = selected },
			background = {
				height = 25,
				border_color = selected and colors_spaces[i],
				color = selected and colors_spaces[i],
				corner_radius = selected and 6,
			},
		})
		space_bracket:set({
			-- background = { border_color = selected and colors.grey or colors.bg2 },
		})
	end)

	space:subscribe("mouse.clicked", function(env)
		if env.BUTTON == "other" then
			space_popup:set({ background = { image = "space." .. env.SID } })
			space:set({ popup = { drawing = "toggle" } })
		else
			local op = (env.BUTTON == "right") and "--destroy" or "--focus"
			sbar.exec("yabai -m space " .. op .. " " .. env.SID)
		end
	end)

	space:subscribe("mouse.exited", function(_)
		space:set({ popup = { drawing = false } })
	end)
end

sbar.add("bracket", {
	spaces[1].name,
	spaces[2].name,
	spaces[3].name,
	spaces[4].name,
	spaces[5].name,
	spaces[6].name,
	spaces[7].name,
	spaces[8].name,
	spaces[9].name,
	spaces[10].name,
}, {
	background = {
		color = colors.background,
		border_color = colors.accent3,
		border_width = 2,
	},
})

local space_window_observer = sbar.add("item", {
	drawing = false,
	updates = true,
})

sbar.add("item", { width = 6 })

local spaces_indicator = sbar.add("item", {
	background = {
		color = colors.with_alpha(colors.grey, 0.0),
		border_color = colors.with_alpha(colors.bg1, 0.0),
		border_width = 0,
		corner_radius = 6,
		height = 24,
		padding_left = 6,
		padding_right = 6,
	},
	icon = {
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Bold"],
			size = 14.0,
		},
		padding_left = 6,
		padding_right = 9,
		color = colors.accent1,
		string = icons.switch.on,
	},
	label = {
		drawing = "off",
		padding_left = 0,
		padding_right = 0,
	},
})

space_window_observer:subscribe("space_windows_change", function(env)
	local icon_line = ""
	local no_app = true
	for app, count in pairs(env.INFO.apps) do
		no_app = false
		local lookup = app_icons[app]
		local icon = ((lookup == nil) and app_icons["default"] or lookup)
		icon_line = icon_line .. utf8.char(0x202F) .. icon
	end

	if no_app then
		icon_line = "—"
	end
	sbar.animate("tanh", 10, function()
		spaces[env.INFO.space]:set({ label = icon_line })
	end)
end)

spaces_indicator:subscribe("swap_menus_and_spaces", function(env)
	local currently_on = spaces_indicator:query().icon.value == icons.switch.on
	spaces_indicator:set({
		icon = currently_on and icons.switch.off or icons.switch.on,
	})
end)

spaces_indicator:subscribe("mouse.entered", function(env)
	sbar.animate("tanh", 30, function()
		spaces_indicator:set({
			background = {
				-- color = { alpha = 1.0 },
				color = colors.tn_black1,
				border_color = { alpha = 1.0 },
				padding_left = 6,
				padding_right = 6,
			},
			icon = {
				color = colors.accent1,
				padding_left = 6,
				padding_right = 9,
			},
			label = { drawing = "off" },
			padding_left = 6,
			padding_right = 6,
		})
	end)
end)

spaces_indicator:subscribe("mouse.exited", function(env)
	sbar.animate("tanh", 30, function()
		spaces_indicator:set({
			background = {
				color = { alpha = 0.0 },
				border_color = { alpha = 0.0 },
			},
			icon = { color = colors.accent1 },
			label = { width = 0 },
		})
	end)
end)

spaces_indicator:subscribe("mouse.clicked", function(env)
	sbar.trigger("swap_menus_and_spaces")
end)

local front_app_icon = sbar.add("item", "front_app_icon", {
	display = "active",
	icon = { drawing = false },
	label = {
		font = "sketchybar-app-font-bg:Regular:21.0",
	},
	updates = true,
	padding_right = 0,
	padding_left = -10,
})

-- disable front_app
-- local front_app = sbar.add("item", "front_app", {
-- 	display = "active",
-- 	icon = { drawing = false },
-- 	label = {
-- 		font = {
-- 			style = settings.font.style_map["Black"],
-- 			size = 12.0,
-- 		},
-- 	},
-- 	updates = true,
-- 	padding_right = 8,
-- 	padding_left = -6,
-- })

front_app_icon:subscribe("front_app_switched", function(env)
	local icon_name = env.INFO
	local lookup = app_icons[icon_name]
	local icon = ((lookup == nil) and app_icons["default"] or lookup)
	front_app_icon:set({ label = { string = icon, color = colors.accent1 } })
	-- front_app:set(
	--    { label = {
	--      -- string = icon_name,
	--      color = colors.accent1,
	--    } }
	-- )
end)

-- front_app:subscribe("mouse.clicked", function(env)
-- 	sbar.trigger("swap_menus_and_spaces")
-- end)

sbar.add("bracket", {
	spaces_indicator.name,
	front_app_icon.name,
	-- front_app.name,
}, {
	background = {
		color = colors.tn_black3,
		border_color = colors.accent1,
		border_width = 2,
	},
})
