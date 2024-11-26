return {
	red = 0xfff7768e,
	orange = 0xffff9e64,
	yellow = 0xffe0af68,
	green = 0xff9ece6a,
	cyan = 0xff7dcfff,
	magenta = 0xffbb9af7,
	accent = 0xff3992eb,
	accent_bright = 0xff3992eb,
	transparent = 0x00000000,
	background = 0xff24283b,

	grey = 0xff7f8490,

	foreground = 0xe0fbf1c7,

	black = 0xe0282828,
	-- pure_green = 0xff00a86b,
	pure_green = 0xff3bb143,
	blue = 0xe0458588,
	-- cyan = 0xe0689d6a,
	white = 0xe0a89984,
	purple = 0xc0ff00f2,

	black_bright = 0xe0928374,
	red_bright = 0xe0fb4934,
	green_bright = 0xe0b8bb26,
	yellow_bright = 0xe0fabd2f,
	blue_bright = 0xe083a598,
	magenta_bright = 0xe0d3869b,
	cyan_bright = 0xe08ec07c,
	white_bright = 0xe0ebdbb2,
	purple_bright = 0xffbb9af7,

	bar = {
		bg = 0xf02c2e34,
		border = 0xff2c2e34,
	},
	popup = {
		bg = 0xc02c2e34,
		border = 0xff7f8490,
	},
	bg1 = 0xff363944,
	bg2 = 0xff414550,

	with_alpha = function(color, alpha)
		if alpha > 1.0 or alpha < 0.0 then
			return color
		end
		return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
	end,

	-- Tokyo Night
	tn_red = 0xfff7768e,
	tn_orange = 0xffff9e64,
	tn_yellow = 0xffe0af68,
	tn_green = 0xff9ece6a,
	tn_light_green = 0xff73daca,
	tn_white_green = 0xffb4f9f8,
	tn_cyan = 0xff2ac3de,
	tn_skyblue = 0xff7dcfff,
	tn_blue = 0xff7aa2f7,
	tn_magenta = 0xffbb9af7,
	tn_white1 = 0xffc0caf5,
	tn_white2 = 0xffa9b1d6,
	tn_white3 = 0xff9aa6ce,
	tn_black1 = 0xff565f89,
	tn_black2 = 0xff414868,
	tn_black3 = 0xff24283b,
	tn_black4 = 0xff1a1b26,

	tn_dark_red = 0xff8c4351,
	tn_brown = 0xff965027,
	tn_dark_yellow = 0xff8f5e15,
	tn_olive = 0xff634f30,
	tn_dark_green = 0xff385f0d,
	tn_teal = 0xff33635c,
	tn_aqua = 0xff006c86,
	tn_navy = 0xff0f4b6e,
	tn_deep_blue = 0xff2959aa,
	tn_purple = 0xff5a3e8e,
	tn_dark_gray = 0xff343b58,
	tn_gray = 0xff40434f,

	cmap_1 = 0xfff7768e,
	cmap_2 = 0xffff4d27,
	cmap_3 = 0xffff8e4a,
	cmap_4 = 0xfff0c36c,
	cmap_5 = 0xffc2e98b,
	cmap_6 = 0xff94fca8,
	cmap_7 = 0xff66fbc1,
	cmap_8 = 0xff38e6d7,
	cmap_9 = 0xff0abfe8,
	cmap_10 = 0xff2388f4,

	accent1 = 0xff00ffff,
	accent2 = 0xff0DB9D7,
	accent3 = 0xc0ff00f2,
	accent4 = 0xff0080ff,

	soft_red = 0xff8c4351,
	soft_white = 0xffeee8d5,
}
