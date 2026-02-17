local wezterm = require("wezterm")
local act = wezterm.action

local module = {}

-- シェル用の文字列エスケープ関数
local function shell_escape(str)
  -- シングルクォートでエスケープ（シングルクォート自体は'\''でエスケープ）
  return "'" .. str:gsub("'", "'\\''") .. "'"
end

-- 選択テキストをplamo-translate-cliで翻訳してオーバーレイペインに表示
local function translate_selection()
  return wezterm.action_callback(function(window, pane)
    -- 選択テキストを取得
    local text = window:get_selection_text_for_pane(pane)

    -- 空チェック
    if not text or text == "" then
      window:toast_notification(
        "Translation Error",
        "No text selected for translation",
        nil,
        3000
      )
      return
    end

    -- plamo-translateコマンドの構築
    -- shell_escape()で安全にエスケープ
    -- lessで結果を表示し続ける（qで閉じる）
    local escaped_text = shell_escape(text)
    local command = string.format(
      "echo %s | plamo-translate --to Japanese | less -R",
      escaped_text
    )

    -- オーバーレイペインで翻訳実行
    local new_pane = pane:split({
      direction = "Bottom",
      size = 1.0,
      args = { os.getenv("SHELL"), "-lc", command },
    })

    -- 新規ペインをフルスクリーン表示
    window:perform_action(act.TogglePaneZoomState, new_pane)
  end)
end

-- 設定にキーバインドを追加
function module.apply_to_config(config)
  -- copy_modeテーブルにYキーを追加
  table.insert(config.key_tables.copy_mode, {
    key = "Y",
    mods = "SHIFT",
    action = translate_selection(),
  })
end

return module
