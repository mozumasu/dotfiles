local wezterm = require("wezterm")

local module = {}

-- nvim で編集して Claude Code の入力欄へ送り込むアクションを定義
function module.edit_prompt()
  return {
    key = "A",
    mods = "CTRL",
    action = wezterm.action_callback(function(_, pane)
      -- 一時ファイルを作成
      local temp_base = os.tmpname()
      os.remove(temp_base)
      local temp_file = temp_base .. ".md"

      -- 取り出したテキストを保持する変数
      local current_text = ""

      -- ペインの寸法を取得して表示行数を得る
      local dims = pane:get_dimensions()
      local viewport_rows = dims and dims.viewport_rows or 0

      -- 画面に見えている範囲のテキストを取得
      local lines = ""
      if viewport_rows > 0 then
        lines = pane:get_lines_as_text(viewport_rows)
      end

      -- 行ごとに分割して配列化（空行も保持）
      local all_lines = {}
      for line in (lines .. "\n"):gmatch("(.-)\r?\n") do
        table.insert(all_lines, line)
      end

      -- 直近のボックスを検出（下から上へ探索）
      local prompt_lines = {}
      local box_end, box_start = 0, 0
      for i = #all_lines, 1, -1 do
        local l = all_lines[i]
        if l:match("^╰─") and box_end == 0 then
          box_end = i
        elseif l:match("^╭─") and box_end > 0 then
          box_start = i
          break
        end
      end

      -- 見つかったボックスの中身を抽出
      if box_start > 0 and box_end > box_start then
        for i = box_start + 1, box_end - 1 do
          local line = all_lines[i] or ""
          local clean = line

          -- NBSP を通常の空白へ置換
          clean = clean:gsub(string.char(194, 160), " ")

          -- 行頭と行末の罫線を個別に除去（UTF-8安全）
          clean = clean:gsub("^│%s*", ""):gsub("^┃%s*", ""):gsub("^|%s*", "")
          clean = clean:gsub("%s*│$", ""):gsub("%s*┃$", ""):gsub("%s*|$", "")

          -- 行頭に > があればその後ろを採用
          local after = clean:match("^%s*>%s*(.*)$")
          local out = after ~= nil and after or clean

          -- 空行もそのまま保持
          table.insert(prompt_lines, out)
        end
      end

      -- ボックスから取れたら結合 取れなければ空のまま
      if #prompt_lines > 0 then
        current_text = table.concat(prompt_lines, "\n")
      else
        current_text = ""
      end

      -- 整形せずにそのまま一時ファイルへ書き出し
      local file = io.open(temp_file, "wb")
      if file then
        file:write(current_text or "")
        file:close()
      end

      -- 下にペインを分割して nvim を起動 終了後に送信処理を実行
      pane:split({
        direction = "Bottom",
        size = 0.4,
        args = {
          "sh",
          "-c",
          string.format(
            [[
            # 変数を定義
            temp_file='%s'
            pane_id='%s'
            wezterm_cli="/Applications/WezTerm.app/Contents/MacOS/wezterm cli"

            # 一時ファイルを nvim で編集
            /opt/homebrew/bin/nvim "$temp_file"

            # 編集結果をチェック
            if [ -s "$temp_file" ]; then
              content=$(cat "$temp_file")
              if [ -n "$content" ]; then
                echo "✓ Sending prompt to Claude Code..."

                # 既存入力を Ctrl+L の生キー送信でクリア
                $wezterm_cli send-text --pane-id="$pane_id" --no-paste $'\x0c'
                sleep 0.05

                # tmpfileから直接 bracketed paste で複数行を送信
                cat "$temp_file" | $wezterm_cli send-text --pane-id="$pane_id"
                
                # 一時ファイルを削除
                rm -f "$temp_file"

                echo "✓ Done!"
                sleep 0.5
              else
                echo "× No content to send"
                rm -f "$temp_file"
                sleep 2
              fi
            else
              echo "× File is empty"
              rm -f "$temp_file"
              sleep 2
            fi
          ]],
            temp_file,
            pane:pane_id()
          ),
        },
      })
    end),
  }
end

return module
