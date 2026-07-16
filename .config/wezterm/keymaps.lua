local wezterm = require("wezterm")
local act = wezterm.action
local overlay = require("keymaps.overlay")
local resize = require("keymaps.pane_resize")

local module = {}

-- set_right_status に一時通知を表示し、3秒後に消す
local function flash_status(window, message)
  window:set_right_status(message)
  wezterm.time.call_after(3, function()
    window:set_right_status("")
  end)
end

-- Ctrl+; は端末エンコーディングに存在せず TUI アプリに届かないため、
-- shell/nvim/herdr のキーバインドと競合しない
local leader = { key = ";", mods = "CTRL", timeout_milliseconds = 2000 }

local keys = {
  -- AltキーをMetaキーとして扱いつつ、バックスラッシュ機能（Alt+¥）は維持する
  { key = "¥", mods = "ALT", action = wezterm.action.SendString("\\") },
  -- ウィンドウ操作
  { key = "Enter", mods = "ALT", action = act.ToggleFullScreen },
  { key = "n", mods = "SUPER", action = act.SpawnWindow },
  -- タブ操作
  { key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
  { key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
  { key = "t", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
  { key = "w", mods = "LEADER", action = act.CloseCurrentTab({ confirm = true }) },
  -- Pane操作
  -- <C-h> has been remapped to Backspace, so Backspace must be specified here
  { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
  { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
  { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
  { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },

  -- フォントサイズ変更
  { key = "+", mods = "SUPER", action = act.IncreaseFontSize },
  { key = "-", mods = "SUPER", action = act.DecreaseFontSize },
  { key = "0", mods = "SUPER", action = act.ResetFontSize },

  { key = "c", mods = "SUPER", action = act.CopyTo("Clipboard") },
  { key = "v", mods = "SUPER", action = act.PasteFrom("Clipboard") },

  -- Debug
  { key = "l", mods = "SUPER", action = act.ShowDebugOverlay },
  { key = "R", mods = "CTRL", action = act.ReloadConfiguration },
  { key = "r", mods = "SUPER", action = act.ReloadConfiguration },

  -- コマンドパレット (Control Shift p)
  { key = "UpArrow", mods = "SHIFT", action = act.ActivateCommandPalette },
  -- 文字選択パレット
  {
    key = "U",
    mods = "CTRL",
    action = act.CharSelect({ copy_on_select = true, copy_to = "ClipboardAndPrimarySelection" }),
  },

  -- モード切替
  -- アクティブペインのズーム切替（ペインが2つ以上の場合のみ）
  {
    key = "Z",
    mods = "LEADER",
    action = wezterm.action_callback(function(window, pane)
      local tab = pane:tab()
      if #tab:panes() > 1 then
        window:perform_action(act.TogglePaneZoomState, pane)
      end
    end),
  },

  -- 誤爆するので非有効にしがち
  -- { key = "k", mods = "SUPER", action = act.ClearScrollback("ScrollbackOnly") },
  -- { key = "m", mods = "SUPER", action = act.Hide },
  -- { key = "H", mods = "CTRL", action = act.HideApplication },

  -- control + space がMaccOSのIME切り替えに使われるので、別のキーに割り当て
  { key = " ", mods = "SUPER", action = act.QuickSelect },

  -- スクロール
  { key = "PageUp", mods = "SHIFT", action = act.ScrollByPage(-1) },
  { key = "PageDown", mods = "SHIFT", action = act.ScrollByPage(1) },
  { key = "p", mods = "ALT|CTRL", action = act.ScrollByPage(-0.5) },
  { key = "n", mods = "ALT|CTRL", action = act.ScrollByPage(0.5) },

  -- コピー・ペースト
  { key = "Copy", mods = "NONE", action = act.CopyTo("Clipboard") },
  { key = "Paste", mods = "NONE", action = act.PasteFrom("Clipboard") },

  -- Claude Codeで改行できるようにする
  { key = "Enter", mods = "SHIFT", action = wezterm.action.SendString("\n") },

  -- herdr の prefix (Ctrl+q)。macos_forward_to_ime_modifier_mask に CTRL が
  -- 含まれるため通常は macSKK に転送され日本語モード中は消費されるが、
  -- WezTerm のキー割り当ては IME 転送より先に判定されるためここで横取りし、
  -- Ctrl+q のバイト (0x11) をペインへ直接送る
  { key = "q", mods = "CTRL", action = act.SendString("\x11") },

  -- kitty プロトコル下では ctrl+[ は esc と別キー扱いになるため esc に変換する。
  -- 合成キーには離しイベントがなく herdr が esc と確定できないため、
  -- 曖昧さのない CSI 27u (kitty 形式の esc 押下) を送る。
  -- kitty を使わないペインには CSI 27u がゴミ文字になるため SendKey (レガシー 1b) に落とす。
  -- 修飾なしの Escape はここに定義してはいけない: キー割り当ては IME 転送より
  -- 先に消費されるため、macSKK の Esc キャンセルが効かなくなる。
  -- 物理 Esc は IME 素通り後に素の 1b + kitty 離しイベントとしてペインに届く
  -- (herdr はこの形式を Esc として解釈できる必要がある)
  {
    key = "[",
    mods = "CTRL",
    action = wezterm.action_callback(function(window, pane)
      local proc = pane:get_foreground_process_name() or ""
      if proc:match("herdr") or proc:match("nvim") then
        window:perform_action(act.SendString("\x1b[27u"), pane)
      else
        window:perform_action(act.SendKey({ key = "Escape" }), pane)
      end
    end),
  },

  -- ScrollToPrompt
  { key = "[", mods = "ALT", action = act.ScrollToPrompt(-1) },
  { key = "]", mods = "ALT", action = act.ScrollToPrompt(1) },

  -- Tab rename (tmux: prefix + ,)
  { key = ",", mods = "LEADER", action = require("tab").rename_prompt_action() },

  -- Pane
  { key = ":", mods = "CTRL", action = act.PaneSelect },
  { key = "r", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) }, -- Control+; → r 横分割
  { key = "d", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) }, -- Control+; → d 縦分割
  { key = "x", mods = "LEADER", action = act({ CloseCurrentPane = { confirm = true } }) }, -- Control+; → x ペインを閉じる

  -- Ctrl+Shift+C: すでに1行に最小化されていれば元の高さ（or 50%）に復元、そうでなければ1行に最小化してラベルを注入
  { key = "c", mods = "CTRL|SHIFT", action = resize.toggle_pane_minimize() },

  -- AWS ARN を Quick Select してブラウザで開く
  {
    key = "a",
    mods = "LEADER",
    action = wezterm.action.QuickSelectArgs({
      label = "open aws console",
      patterns = {
        -- ARNパターン: arn:partition:service:region:account-id:resource
        "\\barn:[\\w\\-]+:[\\w\\-]+:[\\w\\-]*:[0-9]*:[\\w\\-/:=.]+",
      },
      action = wezterm.action_callback(function(window, pane)
        local arn = window:get_selection_text_for_pane(pane)
        wezterm.log_info("opening AWS console for: " .. arn)
        wezterm.open_with("https://console.aws.amazon.com/go/view?arn=" .. arn)
      end),
    }),
  },

  -- Search mode
  {
    key = "f",
    mods = "SUPER",
    action = act.Multiple({
      act.Search("CurrentSelectionOrEmptyString"),
      act.CopyMode("ClearPattern"),
      act.CopyMode("ClearSelectionMode"),
    }),
  },
  {
    key = "X",
    mods = "CTRL",
    action = act.Multiple({
      act.ActivateCopyMode,
      act.CopyMode("ClearPattern"),
      act.CopyMode("ClearSelectionMode"),
      act.CopyMode("MoveToViewportMiddle"),
    }),
  },
  { key = "s", mods = "LEADER", action = act.ActivateKeyTable({ name = "setting_mode", one_shot = false }) },

  -- Codex stash: Ctrl+G を送信 → Neovim が開いたら <leader>S でスタッシュ → :wq で戻る
  {
    key = "u",
    mods = "LEADER",
    action = wezterm.action_callback(function(window, pane)
      -- Ctrl+G を送信して Codex に Neovim を開かせる
      window:perform_action(wezterm.action.SendKey({ key = "g", mods = "CTRL" }), pane)
      -- Neovim が起動するまで待つ（500ms）
      wezterm.time.call_after(0.5, function()
        -- <Space>S でスタッシュ（LazyVim のデフォルト leader = Space）
        window:perform_action(wezterm.action.SendString(" S"), pane)
        -- スタッシュ処理完了を待つ（300ms）
        wezterm.time.call_after(0.3, function()
          -- :wq で保存・終了
          window:perform_action(wezterm.action.SendString(":wq\n"), pane)
          flash_status(window, "📦 Stashed!")
        end)
      end)
    end),
  },

  -- Codex stash pop: スタッシュファイルからポップしてペーストする
  {
    key = "y",
    mods = "LEADER",
    action = wezterm.action_callback(function(window, pane)
      local stash_file = os.getenv("HOME") .. "/.local/share/codex_stash.txt"
      local f = io.open(stash_file, "r")
      if not f then
        flash_status(window, "⚠ Stash empty")
        return
      end
      local content = f:read("*a")
      f:close()
      if content == "" then
        flash_status(window, "⚠ Stash empty")
        return
      end
      -- 末尾の改行を除去
      content = content:gsub("\n$", "")
      window:perform_action(wezterm.action.SendString(content), pane)
      flash_status(window, "📋 Popped!")
    end),
  },
  -- 直前のコマンドと出力をコピー
  {
    key = "z",
    mods = "LEADER",
    action = wezterm.action_callback(function(window, pane)
      -- コピーモードに入る
      window:perform_action(act.ActivateCopyMode, pane)

      -- 直前のInputゾーン（最後のコマンド）に移動
      window:perform_action(act.CopyMode({ MoveBackwardZoneOfType = "Input" }), pane)

      -- セル選択モードを開始
      window:perform_action(act.CopyMode({ SetSelectionMode = "Cell" }), pane)

      -- 次のPromptゾーンまで選択（コマンドと出力を含む）
      window:perform_action(act.CopyMode({ MoveForwardZoneOfType = "Prompt" }), pane)

      -- 1行上に移動して行末へ（現在のプロンプト行を除外）
      window:perform_action(act.CopyMode("MoveUp"), pane)
      window:perform_action(act.CopyMode("MoveToEndOfLineContent"), pane)

      -- クリップボードにコピー
      window:perform_action(
        act.Multiple({
          { CopyTo = "ClipboardAndPrimarySelection" },
          { Multiple = { "ScrollToBottom", { CopyMode = "Close" } } },
        }),
        pane
      )

      flash_status(window, "📋 Copied!")
    end),
  },
  -- バッファの内容をNeovimで表示（色付き）
  {
    key = "b",
    mods = "LEADER",
    action = wezterm.action_callback(function(window, pane)
      local pane_id = tostring(pane:pane_id())

      -- Neovimの WezCapture コマンドで色付き表示
      local new_pane = pane:split({
        direction = "Right",
        size = 1.0,
        args = {
          os.getenv("SHELL"),
          "-lc",
          "nvim -c 'WezCapture " .. pane_id .. "'",
        },
      })
      new_pane:activate()
      window:perform_action(act.TogglePaneZoomState, new_pane)
    end),
  },
}

function module.apply_to_config(config)
  config.disable_default_key_bindings = true
  config.leader = leader

  config.keys = config.keys or {}
  for _, key in ipairs(keys) do
    table.insert(config.keys, key)
  end

  config.key_tables = config.key_tables or {}
  for name, table_def in pairs(require("keymaps.key_tables")) do
    config.key_tables[name] = table_def
  end

  require("keymaps.command_palette").setup()
end

return module
