local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

local menu_watcher = sbar.add("item", {
	drawing = false,
	updates = false,
})
local space_menu_swap = sbar.add("item", {
	drawing = false,
	updates = true,
})
sbar.add("event", "swap_menus_and_spaces")

local max_items = 15
local menu_items = {}
for i = 1, max_items, 1 do
	local menu = sbar.add("item", "menu." .. i, {
		padding_left = settings.paddings,
		padding_right = settings.paddings,
		drawing = false,
		icon = { drawing = false },
		label = {
			color = colors.accent1,
			font = {
				style = settings.font.style_map[i == 1 and "Heavy" or "Semibold"],
				size = 12.0,
			},
			padding_left = 6,
			padding_right = 6,
		},
		click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s " .. i,
	})

	menu_items[i] = menu
end

sbar.add("bracket", { "/menu\\..*/" }, {
	background = {
		color = colors.tn_black3,
		border_color = colors.accent3,
		border_width = 2,
	},
})

local menu_padding = sbar.add("item", "menu.padding", {
	drawing = false,
	width = 5,
})

local function update_menus(env)
	sbar.exec("$CONFIG_DIR/helpers/menus/bin/menus -l", function(menus)
		sbar.set("/menu\\..*/", { drawing = false })
		sbar.set("/space\\..*/", { drawing = false })
		sbar.set("front_app", { drawing = false })

		menu_padding:set({ drawing = true })
		id = 1
		for menu in string.gmatch(menus, "[^\r\n]+") do
			if id < max_items then
				menu_items[id]:set({ label = menu, drawing = true })
			else
				break
			end
			id = id + 1
		end
	end)
end

menu_watcher:subscribe("front_app_switched", update_menus)

space_menu_swap:subscribe("swap_menus_and_spaces", function(env)
	local drawing = menu_items[1]:query().geometry.drawing == "on"
	if drawing then
		menu_watcher:set({ updates = false })
		sbar.set("/menu\\..*/", { drawing = false })
		sbar.set("/space\\..*/", { drawing = true })
		sbar.set("front_app", { drawing = true })
	else
		menu_watcher:set({ updates = true })

		-- Disable the following lines to avoid sticking the front_app after switching
		-- sbar.set("/space\\..*/", { drawing = false })
		-- sbar.set("front_app", { drawing = false })
		update_menus()
	end
end)

return menu_watcher
