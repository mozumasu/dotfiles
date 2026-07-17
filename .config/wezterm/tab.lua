local wezterm = require("wezterm")
local act = wezterm.action
local palette = require("colors")
local module = {}

-- Custom tab titles (tab_id -> string or nil)
module.custom_title = {}

-- =============================================================================
-- 定数
-- =============================================================================

-- Icons
local ICONS = {
  docker = wezterm.nerdfonts.md_docker,
  neovim = wezterm.nerdfonts.linux_neovim,
  nb = wezterm.nerdfonts.md_notebook,
  ssh = wezterm.nerdfonts.md_lan,
  claude = "✳",
  fallback = wezterm.nerdfonts.dev_terminal,
  zoom = wezterm.nerdfonts.md_magnify,
}

-- Icon colors
local ICON_COLORS = {
  docker = "#4169e1",
  neovim = "#57A143",
  nb = palette.nb,
  ssh = palette.ssh,
  claude = "#D97757",
}

-- Tab colors
local TAB_COLORS = {
  foreground_inactive = "#a0a9cb",
  background_inactive = "none",
  foreground_active = palette.accent_fg,
  background_active = palette.accent,
  background_ssh_active = palette.ssh,
  foreground_ssh_active = "#ffffff",
}

-- Tab decorations
local DECORATIONS = {
  left_circle = wezterm.nerdfonts.ple_left_half_circle_thick,
  right_circle = wezterm.nerdfonts.ple_right_half_circle_thick,
}

-- pane_state の掃除を行う update-status イベントの間隔
local PRUNE_INTERVAL = 100

-- =============================================================================
-- ヘルパー関数
-- =============================================================================

local function basename(path)
  return string.gsub(path or "", "(.*[/\\])(.*)", "%2")
end

local function is_nb_process(process_name, cwd)
  return process_name == "nb" or (cwd and cwd:find("%.nb") ~= nil)
end

local function is_ssh_process(process_name, user_vars)
  if user_vars.ssh_host and user_vars.ssh_host ~= "" then
    return true, user_vars.ssh_host
  end
  if process_name == "ssh" then
    return true, nil
  end
  return false, nil
end

local function is_claude_title(pane_title)
  return pane_title:find("^✳") ~= nil or pane_title:lower():find("claude", 1, true) ~= nil
end

local function is_claude_process(process_name, pane_title)
  return process_name == "claude" or is_claude_title(pane_title)
end

local function extract_project_name(cwd)
  if not cwd then
    return "-"
  end

  local home = os.getenv("HOME")
  if home and cwd:sub(1, #home) == home then
    cwd = "~" .. cwd:sub(#home + 1)
  end

  -- nbディレクトリ
  if cwd:find("%.nb") then
    return "nb"
  end

  -- GitHubプロジェクト名
  local _, project = cwd:match(".*/src/github.com/([^/]+)/([^/]+)")
  if project then
    return project
  end

  -- 最後のディレクトリ名
  cwd = cwd:gsub("/$", "")
  return cwd:match("([^/]+)$") or cwd
end

local function get_icon_and_color(ctx)
  if ctx.is_ssh then
    local color = ctx.is_active and TAB_COLORS.foreground_ssh_active or ICON_COLORS.ssh
    return ICONS.ssh, color
  end

  if ctx.pane_title == "nvim" or ctx.process_name == "nvim" then
    return ICONS.neovim, ICON_COLORS.neovim
  end

  if is_nb_process(ctx.process_name, ctx.cwd) then
    return ICONS.nb, ICON_COLORS.nb
  end

  if ctx.is_claude then
    return ICONS.claude, ICON_COLORS.claude
  end

  if ctx.process_name == "docker" or ctx.pane_title:find("docker", 1, true) then
    return ICONS.docker, ICON_COLORS.docker
  end

  return ICONS.fallback, TAB_COLORS.foreground_inactive
end

local function get_tab_colors(is_active, is_ssh)
  if is_active and is_ssh then
    return TAB_COLORS.background_ssh_active, TAB_COLORS.foreground_ssh_active
  elseif is_active then
    return TAB_COLORS.background_active, TAB_COLORS.foreground_active
  end
  return TAB_COLORS.background_inactive, TAB_COLORS.foreground_inactive
end

local function has_zoomed_pane(panes)
  for _, pane_info in ipairs(panes) do
    if pane_info.is_zoomed then
      return true
    end
  end
  return false
end

-- タブ名を対話的に変更する action（空入力でカスタムタイトルをリセット）
function module.rename_prompt_action()
  return wezterm.action_callback(function(window, pane)
    local tab_id = pane:tab():tab_id()
    local current = module.custom_title[tab_id] or ""
    window:perform_action(
      act.PromptInputLine({
        description = "(wezterm) Rename tab (empty to reset):",
        initial_value = current,
        action = wezterm.action_callback(function(_, inner_pane, line)
          if line == nil then
            return
          end
          local t = inner_pane:tab()
          if line == "" then
            module.custom_title[t:tab_id()] = nil
          else
            module.custom_title[t:tab_id()] = line
          end
        end),
      }),
      pane
    )
  end)
end

-- =============================================================================
-- メイン処理
-- =============================================================================

function module.apply_to_config(config)
  -- タブバー設定（format-tab-title の描画がモードや幅に依存するためここで持つ）
  config.show_tabs_in_tab_bar = true
  config.hide_tab_bar_if_only_one_tab = false
  config.tab_bar_at_bottom = true
  config.show_new_tab_button_in_tab_bar = false
  config.show_close_tab_button_in_tabs = false -- Can only be used in nightly
  config.tab_max_width = 30
  config.use_fancy_tab_bar = true
  -- use_fancy_tab_bar = trueの場合のタブバー透過設定
  config.window_frame = {
    inactive_titlebar_bg = "none",
    active_titlebar_bg = "none",
  }
  -- use_fancy_tab_bar = falseの場合のタブバー透過設定
  -- (config.colors はカーソル・選択色を持つ appearance.lua と共有のためマージする)
  config.colors = config.colors or {}
  config.colors.tab_bar = {
    background = "none",
    inactive_tab_edge = "none",
  }

  -- pane_id -> { raw_cwd, title, ssh_host, is_claude }
  local pane_state = {}
  local update_count = 0

  local function get_state(pane_id)
    local state = pane_state[pane_id]
    if not state then
      state = {}
      pane_state[pane_id] = state
    end
    return state
  end

  -- 閉じた pane のエントリを削除する
  local function prune_dead_panes()
    local alive = {}
    for _, mux_window in ipairs(wezterm.mux.all_windows()) do
      for _, mux_tab in ipairs(mux_window:tabs()) do
        for _, mux_pane in ipairs(mux_tab:panes()) do
          alive[mux_pane:pane_id()] = true
        end
      end
    end
    for pane_id in pairs(pane_state) do
      if not alive[pane_id] then
        pane_state[pane_id] = nil
      end
    end
  end

  -- pane 状態キャッシュの更新
  wezterm.on("update-status", function(_, pane)
    local state = get_state(pane:pane_id())
    local user_vars = pane:get_user_vars() or {}

    -- SSH中以外はタイトルキャッシュを更新
    if not (user_vars.ssh_host and user_vars.ssh_host ~= "") then
      local cwd_url = pane:get_current_working_dir()
      local cwd = cwd_url and cwd_url.file_path
      -- cwd が変わった場合のみ extract_project_name を実行
      if cwd ~= state.raw_cwd then
        state.raw_cwd = cwd
        state.title = extract_project_name(cwd)
      end
    end

    -- Claude Code検出キャッシュ（update-statusで安定的に判定）
    local process_name = basename(pane:get_foreground_process_name() or "")
    local pane_title = pane:get_title() or ""
    if is_claude_process(process_name, pane_title) then
      state.is_claude = true
    elseif
      (process_name == "zsh" or process_name == "bash" or process_name == "fish")
      and not is_claude_title(pane_title)
    then
      state.is_claude = nil
    end

    update_count = update_count + 1
    if update_count % PRUNE_INTERVAL == 0 then
      prune_dead_panes()
    end
  end)

  -- タブタイトルのフォーマット
  wezterm.on("format-tab-title", function(tab, _, _, _, _, max_width)
    local pane = tab.active_pane
    local state = get_state(pane.pane_id)
    local process_name = basename(pane.foreground_process_name)
    local pane_title = pane.title or ""
    local user_vars = pane.user_vars or {}
    local raw_cwd = state.raw_cwd

    -- SSH判定
    local is_ssh, ssh_host = is_ssh_process(process_name, user_vars)
    if is_ssh and ssh_host then
      state.ssh_host = ssh_host
    elseif not is_ssh then
      state.ssh_host = nil
    end

    -- Claude Code検出（update-statusでキャッシュ済み）
    local is_claude = state.is_claude or false

    -- タブの色
    local background, foreground = get_tab_colors(tab.is_active, is_ssh)
    local edge_background = "transparent"
    local edge_foreground = background

    -- タイトルテキスト（カスタムタイトル > CLI設定タイトル > SSH > nb > CWD）
    local title_text
    local custom = module.custom_title[tab.tab_id] or (tab.tab_title ~= "" and tab.tab_title or nil)
    if custom then
      title_text = custom
    elseif is_ssh then
      title_text = state.ssh_host or "ssh"
    elseif is_nb_process(process_name, raw_cwd) then
      title_text = "nb"
    else
      title_text = state.title or "-"
    end

    -- Claude Code のタイトル追加（カスタムタイトル時はアイコンのみ）
    local claude_suffix = ""
    if not custom and is_claude and pane_title ~= "" then
      claude_suffix = " " .. pane_title
    end

    -- アイコン
    local icon, icon_color = get_icon_and_color({
      process_name = process_name,
      pane_title = pane_title,
      cwd = raw_cwd,
      is_ssh = is_ssh,
      is_active = tab.is_active,
      is_claude = is_claude,
    })

    -- ズームインジケーター
    local zoom_indicator = has_zoomed_pane(tab.panes) and (ICONS.zoom .. " ") or ""

    -- 半円（アクティブタブのみ）
    local left_circle = tab.is_active and DECORATIONS.left_circle or ""
    local right_circle = tab.is_active and DECORATIONS.right_circle or ""

    -- タイトルの整形
    local title = " " .. wezterm.truncate_right(title_text, max_width)
    local claude_title = wezterm.truncate_right(claude_suffix, max_width) .. " "

    return {
      { Background = { Color = edge_background } },
      { Text = " " },
      { Foreground = { Color = edge_foreground } },
      { Text = left_circle },
      { Background = { Color = background } },
      { Foreground = { Color = icon_color } },
      { Text = icon },
      { Background = { Color = background } },
      { Foreground = { Color = foreground } },
      { Text = zoom_indicator },
      { Attribute = { Intensity = "Bold" } },
      { Text = title },
      { Attribute = { Intensity = "Normal" } },
      { Text = claude_title },
      { Background = { Color = edge_background } },
      { Foreground = { Color = edge_foreground } },
      { Text = right_circle },
    }
  end)
end

return module
