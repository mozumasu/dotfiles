-- =============================================================================
-- タブバーの見た目カスタマイズ（シンプル版）
--
-- プロセス検出やSSH判定などを省いた、色と形だけの最小構成です。
-- 使い方: wezterm.lua で tab.lua の代わりにこれを読み込む
--   require("examples.tab_simple").apply_to_config(config)
-- (単体で配布する場合は ~/.config/wezterm/ 直下にコピーして
--  require("tab_simple") にする)
-- =============================================================================

local wezterm = require("wezterm")
local module = {}

-- -----------------------------------------------------------------------------
-- 色の設定: ここを書き換えるだけで配色を変えられます
-- -----------------------------------------------------------------------------
local COLORS = {
  -- アクティブ（選択中）タブ
  active_bg = "#80EBDF", -- 背景色
  active_fg = "#313244", -- 文字色

  -- 非アクティブタブ（背景を "none" にすると炎の縁取りも見えなくなる）
  inactive_bg = "#313244",
  inactive_fg = "#a0a9cb",
}

-- タブの右端につける炎の縁取り
local RIGHT_FLAME = wezterm.nerdfonts.ple_flame_thick

-- -----------------------------------------------------------------------------
-- アイコンの設定: タブごとにここからランダムで1つ選んで常時表示する
-- -----------------------------------------------------------------------------
local ICON_LIST = {
  { glyph = wezterm.nerdfonts.custom_go, color = "#00ADD8" },
  { glyph = wezterm.nerdfonts.dev_argocd, color = "#EF7B4D" },
}

-- -----------------------------------------------------------------------------
-- リポジトリ名の検出
-- -----------------------------------------------------------------------------

-- 一度調べた cwd の結果を覚えておく（タブの再描画は頻繁に起こるため）
-- 値: リポジトリ名 / false（.git が見つからなかった記録）
local repo_name_cache = {}

-- cwd から親ディレクトリを順に辿り、.git がある場所のディレクトリ名を返す
-- 見つからなければ nil
local function find_repo_name(cwd)
  if not cwd or cwd == "" then
    return nil
  end
  if repo_name_cache[cwd] ~= nil then
    return repo_name_cache[cwd] or nil
  end

  local dir = cwd:gsub("/$", "")
  while dir ~= "" do
    -- os.rename(同じパス, 同じパス) は存在チェックの代用
    -- （.git がディレクトリでも worktree のようなファイルでも判定できる）
    if os.rename(dir .. "/.git", dir .. "/.git") then
      local name = dir:match("([^/]+)$")
      repo_name_cache[cwd] = name
      return name
    end
    -- 1つ上のディレクトリへ
    dir = dir:match("(.*)/[^/]*$") or ""
  end

  repo_name_cache[cwd] = false
  return nil
end

-- -----------------------------------------------------------------------------
-- アイコンの抽選
-- -----------------------------------------------------------------------------

-- タブごとに一度だけ抽選した結果を覚えておく
-- （再描画のたびに引き直すとアイコンがチカチカ切り替わってしまう）
local tab_icon_cache = {}

local function pick_icon(tab_id)
  if not tab_icon_cache[tab_id] then
    tab_icon_cache[tab_id] = ICON_LIST[math.random(#ICON_LIST)]
  end
  return tab_icon_cache[tab_id]
end

-- -----------------------------------------------------------------------------
-- メイン処理
-- -----------------------------------------------------------------------------
function module.apply_to_config(config)
  -- タブバー自体の設定
  config.use_fancy_tab_bar = false -- レトロスタイル（フォント設定が効く）
  config.tab_bar_at_bottom = true -- タブバーを下に表示
  config.hide_tab_bar_if_only_one_tab = false -- タブが1つでも表示する
  config.show_new_tab_button_in_tab_bar = false -- 「+」ボタンを消す
  config.tab_max_width = 30 -- タブの最大幅

  -- タブバーの背景を透過する
  -- (config.colors は他のファイルとも共有するので、丸ごと代入せずマージする)
  config.colors = config.colors or {}
  config.colors.tab_bar = {
    background = "none",
    inactive_tab_edge = "none",
  }

  -- タブのタイトルを描画する
  wezterm.on("format-tab-title", function(tab, tabs, _, _, _, max_width)
    -- アクティブかどうかで色を切り替える
    local bg = tab.is_active and COLORS.active_bg or COLORS.inactive_bg
    local fg = tab.is_active and COLORS.active_fg or COLORS.inactive_fg

    -- 右端の炎は次のタブの背景色の上に描くことで、タブ同士が繋がって見える
    -- （tabs は 1 始まり、tab_index は 0 始まりなので +2 が次のタブ）
    local next_tab = tabs[tab.tab_index + 2]
    local flame_bg = "none"
    if next_tab then
      flame_bg = next_tab.is_active and COLORS.active_bg or COLORS.inactive_bg
    end

    -- 表示名: git リポジトリ内ならリポジトリ名、それ以外はパネルのタイトル
    local cwd_url = tab.active_pane.current_working_dir
    local cwd = cwd_url and cwd_url.file_path
    local label = find_repo_name(cwd) or tab.active_pane.title
    local icon = pick_icon(tab.tab_id)

    -- アイコンの色: アクティブタブでは背景と同化しやすいので文字色に合わせる
    local icon_color = tab.is_active and fg or icon.color

    -- タブ番号 + 表示名
    -- 右の炎(1) + アイコン(3) のぶんを max_width から引いて切り詰めないと、
    -- タブ幅の上限を超えて右の炎が切れる
    local title = string.format(" %d: %s ", tab.tab_index + 1, label)
    title = wezterm.truncate_right(title, max_width - 4)

    -- 描画パーツを順番に並べて返す
    return {
      -- アイコン
      { Background = { Color = bg } },
      { Foreground = { Color = icon_color } },
      { Text = " " .. icon.glyph },
      -- タイトル本体（アクティブタブは太字）
      { Background = { Color = bg } },
      { Foreground = { Color = fg } },
      { Attribute = { Intensity = tab.is_active and "Bold" or "Normal" } },
      { Text = title },
      { Attribute = { Intensity = "Normal" } },
      -- 右の炎（次のタブとの区切り）
      { Background = { Color = flame_bg } },
      { Foreground = { Color = bg } },
      { Text = RIGHT_FLAME },
    }
  end)
end

return module
