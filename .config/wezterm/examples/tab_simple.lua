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

  -- 非アクティブタブ
  inactive_bg = "none", -- "none" で透過
  inactive_fg = "#a0a9cb",
}

-- タブの左右につける半円（丸タブの見た目を作る）
local LEFT_CIRCLE = wezterm.nerdfonts.ple_left_half_circle_thick
local RIGHT_CIRCLE = wezterm.nerdfonts.ple_right_half_circle_thick

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
  wezterm.on("format-tab-title", function(tab, _, _, _, _, max_width)
    -- アクティブかどうかで色を切り替える
    local bg = tab.is_active and COLORS.active_bg or COLORS.inactive_bg
    local fg = tab.is_active and COLORS.active_fg or COLORS.inactive_fg

    -- 表示名: git リポジトリ内ならリポジトリ名、それ以外はパネルのタイトル
    local cwd_url = tab.active_pane.current_working_dir
    local cwd = cwd_url and cwd_url.file_path
    local label = find_repo_name(cwd) or tab.active_pane.title

    -- タブ番号 + 表示名
    -- 左の余白(1) + 左右の半円(2) のぶんを max_width から引いて切り詰めないと、
    -- タブ幅の上限を超えて右の半円が切れる
    local title = string.format(" %d: %s ", tab.tab_index + 1, label)
    title = wezterm.truncate_right(title, max_width - 3)

    -- 半円はアクティブタブだけに付ける
    local left = tab.is_active and LEFT_CIRCLE or ""
    local right = tab.is_active and RIGHT_CIRCLE or ""

    -- 描画パーツを順番に並べて返す
    return {
      -- 左の半円（背景色を文字色として描くことで丸く見せる）
      { Background = { Color = "none" } },
      { Foreground = { Color = bg } },
      { Text = " " .. left },
      -- タイトル本体
      { Background = { Color = bg } },
      { Foreground = { Color = fg } },
      { Text = title },
      -- 右の半円
      { Background = { Color = "none" } },
      { Foreground = { Color = bg } },
      { Text = right },
    }
  end)
end

return module
