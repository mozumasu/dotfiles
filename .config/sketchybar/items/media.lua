local icons = require("icons")
local colors = require("colors")
local settings = require("settings")
local whitelist = { ["Spotify"] = true, ["Music"] = true, ["Google Chrome"] = true }

local media_cover = sbar.add("item", {
	position = "right",
	background = {
		image = {
			string = "media.artwork",
			scale = 0.85,
		},
		color = colors.transparent,
		border_width = 0,
	},
	label = { drawing = false },
	icon = { drawing = false },
	drawing = false,
	updates = true,
	popup = {
		align = "center",
		horizontal = true,
		background = {
			color = colors.tn_black3,
			border_color = colors.accent1,
			border_width = 2,
		},
	},
})

local media_artist = sbar.add("item", {
	position = "right",
	drawing = false,
	padding_left = 3,
	padding_right = 0,
	width = 0,
	icon = { drawing = false },
	label = {
		width = 0,
		font = {
			size = 9,
			style = settings.font.style_map["Bold"],
		},
		color = colors.accent3,
		max_chars = 18,
		y_offset = 6,
	},
	background = { drawing = "off" },
})

local media_title = sbar.add("item", {
	position = "right",
	drawing = false,
	padding_left = 3,
	padding_right = 0,
	icon = { drawing = false },
	label = {
		font = {
			size = 11,
			style = settings.font.style_map["Bold"],
		},
		width = 0,
		max_chars = 16,
		y_offset = -5,
		color = colors.accent1,
	},
})

sbar.add("item", {
	position = "popup." .. media_cover.name,
	icon = {
		string = icons.media.back,
		font = { size = 10 },
		color = colors.accent1,
	},
	label = { drawing = false },
	click_script = "nowplaying-cli previous",
})
sbar.add("item", {
	position = "popup." .. media_cover.name,
	icon = {
		string = icons.media.play_pause,
		font = { size = 10 },
		color = colors.accent1,
	},
	label = { drawing = false },
	click_script = "nowplaying-cli togglePlayPause",
})
sbar.add("item", {
	position = "popup." .. media_cover.name,
	icon = {
		string = icons.media.forward,
		font = { size = 10 },
		color = colors.accent1,
	},
	label = { drawing = false },
	click_script = "nowplaying-cli next",
})

local interrupt = 0
local function animate_detail(detail)
	if not detail then
		interrupt = interrupt - 1
	end
	if interrupt > 0 and not detail then
		return
	end

	sbar.animate("tanh", 30, function()
		media_artist:set({ label = { width = detail and "dynamic" or 0 } })
		media_title:set({ label = { width = detail and "dynamic" or 0 } })
	end)
end

media_cover:subscribe("media_change", function(env)
	if whitelist[env.INFO.app] then
		local drawing = (env.INFO.state == "playing" or env.INFO.state == "paused")
		media_artist:set({ drawing = drawing, label = env.INFO.artist })
		media_title:set({ drawing = drawing, label = env.INFO.title })
		media_cover:set({ drawing = drawing })

		if drawing then
			animate_detail(true)
			interrupt = interrupt + 1
			sbar.delay(5, animate_detail)
		else
			media_cover:set({ popup = { drawing = false } })
		end
	end
end)

media_cover:subscribe("mouse.entered", function(env)
	interrupt = interrupt + 1
	animate_detail(true)
end)

media_cover:subscribe("mouse.exited", function(env)
	animate_detail(false)
end)

media_cover:subscribe("mouse.clicked", function(env)
	media_cover:set({ popup = { drawing = "toggle" } })
end)

media_title:subscribe("mouse.exited.global", function(env)
	media_cover:set({ popup = { drawing = false } })
end)
