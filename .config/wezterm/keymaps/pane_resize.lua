local wezterm = require("wezterm")
local act = wezterm.action

local module = {}

-- 軸ごとのフィールド名と AdjustPaneSize の方向。
-- 先頭側 (top/left が 0) の pane は縮小/拡大の方向が反転する
local AXES = {
  rows = { pane_field = "viewport_rows", tab_field = "rows", edge_field = "top", start_dir = "Up", end_dir = "Down" },
  cols = { pane_field = "cols", tab_field = "cols", edge_field = "left", start_dir = "Left", end_dir = "Right" },
}

-- ペインのサイズを tab に対する指定パーセンテージに合わせる内部処理
local function apply_pane_size_percent(window, pane, percent, axis)
  local spec = AXES[axis]
  local tab = pane:tab()
  local tab_size = tab:get_size()
  local pane_dims = pane:get_dimensions()
  local pane_id = pane:pane_id()

  local is_first = false
  for _, info in ipairs(tab:panes_with_info()) do
    if info.pane:pane_id() == pane_id then
      is_first = (info[spec.edge_field] == 0)
      break
    end
  end

  local target = math.floor(tab_size[spec.tab_field] * percent)
  local diff = pane_dims[spec.pane_field] - target
  local shrink_dir = is_first and spec.start_dir or spec.end_dir
  local grow_dir = is_first and spec.end_dir or spec.start_dir

  if diff > 0 then
    window:perform_action(act.AdjustPaneSize({ shrink_dir, diff }), pane)
  elseif diff < 0 then
    window:perform_action(act.AdjustPaneSize({ grow_dir, -diff }), pane)
  end
end

function module.set_pane_height_percent(percent)
  return wezterm.action_callback(function(window, pane)
    apply_pane_size_percent(window, pane, percent, "rows")
  end)
end

function module.set_pane_width_percent(percent)
  return wezterm.action_callback(function(window, pane)
    apply_pane_size_percent(window, pane, percent, "cols")
  end)
end

-- ペインの最小化前の高さを記憶するテーブル (pane_id -> percent)
local pane_height_store = {}

-- すでに1行に最小化されていれば元の高さ（or 50%）に復元、
-- そうでなければ1行に最小化してラベルを注入する
function module.toggle_pane_minimize()
  return wezterm.action_callback(function(window, pane)
    local pane_dims = pane:get_dimensions()
    local pane_id = pane:pane_id()

    -- すでに1行に最小化されている場合は元の高さ（記憶がなければ50%）に復元
    if pane_dims.viewport_rows <= 1 then
      local restore_percent = pane_height_store[pane_id] or 0.5
      pane_height_store[pane_id] = nil
      apply_pane_size_percent(window, pane, restore_percent, "rows")
      return
    end

    -- 最小化前に現在の高さ比率を保存
    local tab = pane:tab()
    local tab_size = tab:get_size()
    pane_height_store[pane_id] = pane_dims.viewport_rows / tab_size.rows

    local title = pane:get_title()
    local cwd_uri = pane:get_current_working_dir()
    local cwd = cwd_uri and cwd_uri.file_path:match("([^/]+)/?$") or ""
    -- titleがcwdと同じ場合はプロセス名にフォールバック
    local name
    if title ~= "" and title ~= cwd then
      name = title
    else
      local process = pane:get_foreground_process_name()
      name = process and process:match("([^/]+)$") or "?"
    end
    local label = cwd ~= "" and (name .. " (" .. cwd .. ")") or name
    apply_pane_size_percent(window, pane, 0, "rows") -- 現在のペインを1行に最小化
    -- リサイズ完了後にラベルを注入
    wezterm.time.call_after(0.05, function()
      pane:inject_output("\r\x1b[2K\x1b[33m◀ " .. label .. " ▶\x1b[0m")
    end)
  end)
end

return module
