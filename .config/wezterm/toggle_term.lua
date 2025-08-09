local wezterm = require("wezterm")

local module = {}

-- Function toggle terminal pane
function module.toggle_term()
  return {
    key = "j",
    mods = "SHIFT|CTRL",
    action = wezterm.action_callback(function(window, pane)
      local tab = pane:tab()
      local panes = tab:panes()
      local panes_count = #panes

      -- If there is only one pane, split it down below
      if panes_count == 1 then
        pane:split({ direction = "Bottom", size = 0.3 })
        -- Focus on newly created pane (bottom)
        window:perform_action(wezterm.action.ActivatePaneDirection("Down"), pane)
        return
      end

      -- If there are multiple panes
      local panes_with_info = tab:panes_with_info()
      local is_zoomed = false
      local active_pane = nil

      -- Check current status
      for _, pane_info in ipairs(panes_with_info) do
        if pane_info.is_active then
          active_pane = pane_info
          is_zoomed = pane_info.is_zoomed
          break
        end
      end

      if is_zoomed then
        -- If zooming, cancel (display all panes)
        window:perform_action(wezterm.action.TogglePaneZoomState, pane)

        -- Find the bottom pane (terminal) and focus
        local bottom_pane = nil
        local max_y = -1

        for _, pane_info in ipairs(panes_with_info) do
          if pane_info.top > max_y then
            max_y = pane_info.top
            bottom_pane = pane_info.pane
          end
        end

        if bottom_pane then
          bottom_pane:activate()
        end
      else
        -- If you are not zooming
        -- Find the top pane (main pane)
        local top_pane = nil
        local min_y = 999999

        for _, pane_info in ipairs(panes_with_info) do
          if pane_info.top < min_y then
            min_y = pane_info.top
            top_pane = pane_info.pane
          end
        end

        -- Focus on the main pane (top) and zoom (hides the bottom pane)
        if top_pane then
          top_pane:activate()
          window:perform_action(wezterm.action.TogglePaneZoomState, top_pane)
        end
      end
    end),
  }
end

return module
