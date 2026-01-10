return {
  "m00qek/baleia.nvim",
  version = "*",
  -- Keep plugin lazy, but expose commands/autocmds early.
  -- We lazy-require baleia in callbacks as needed.
  init = function()
    ---@class BaleiaObj
    ---@field once fun(buffer: integer)
    ---@field automatically fun(buffer: integer)
    ---@field logger { show: fun() }

    -- Lazy loader for baleia
    local function ensure_baleia()
      if vim.g.baleia then
        return vim.g.baleia
      end
      local ok, mod = pcall(require, "baleia")
      if not ok then
        return nil
      end
      local b = mod.setup({})
      vim.g.baleia = b
      return b
    end

    -- 最小VTレンダラ（前回のまま）...
    local function render_ansi_current_buf()
      local win = vim.api.nvim_get_current_win()
      local cols = math.max(vim.api.nvim_win_get_width(win), 240)

      local raw = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
      raw = raw:gsub("\r\n", "\n"):gsub("\r", "\n")
      raw = raw:gsub("\27%].-\7", ""):gsub("\27%].-\27\\", "")

      local rows = {}
      local function ensure_row(r)
        while #rows < r do
          rows[#rows + 1] = {}
        end
      end
      local function ensure_cols(row)
        if #row < cols then
          for i = #row + 1, cols do
            row[i] = ""
          end
        end
      end

      local cur_r, cur_c = 1, 1
      local pen, last_pen = "\27[0m", ""
      local saved_r, saved_c = 1, 1

      local function set_char(r, c, ch, sgr)
        if r < 1 or c < 1 or c > cols then
          return
        end
        ensure_row(r)
        local row = rows[r]
        ensure_cols(row)
        if sgr ~= last_pen then
          row[c] = (row[c] or "") .. sgr .. ch
          last_pen = sgr
        else
          row[c] = (row[c] or "") .. ch
        end
      end
      local function clear_line_segment(r, s, e)
        ensure_row(r)
        local row = rows[r]
        ensure_cols(row)
        for x = s, e do
          row[x] = ""
        end
      end
      local function scroll_up(n)
        n = math.max(1, n)
        if n > #rows then
          rows = {}
          cur_r, cur_c = 1, 1
          return
        end
        for _ = 1, n do
          table.remove(rows, 1)
        end
        for _ = 1, n do
          rows[#rows + 1] = {}
        end
      end
      local function scroll_down(n)
        n = math.max(1, n)
        for _ = 1, n do
          table.insert(rows, 1, {})
        end
        cur_r = cur_r + n
      end

      local i, len = 1, #raw
      while i <= len do
        local ch = raw:sub(i, i)
        if ch == "\n" then
          cur_r = cur_r + 1
          cur_c = 1
          last_pen = ""
          i = i + 1
        elseif ch == "\t" then
          local next_tab = math.floor((cur_c - 1) / 8) * 8 + 9
          cur_c = math.min(cols, next_tab)
          i = i + 1
        elseif ch == "\b" then
          cur_c = math.max(1, cur_c - 1)
          i = i + 1
        elseif ch == "\r" then
          cur_c = 1
          last_pen = ""
          i = i + 1
        elseif ch == "\27" and raw:sub(i + 1, i + 1) == "[" then
          local j = i + 2
          while j <= len do
            local cj = raw:sub(j, j)
            if cj:match("[@-~]") then
              break
            end
            j = j + 1
          end
          if j > len then
            break
          end
          local body, fin = raw:sub(i + 2, j - 1), raw:sub(j, j)
          local norm = body:gsub(":", ";")
          local nums = {}
          for n in norm:gmatch("(%d+)") do
            nums[#nums + 1] = tonumber(n)
          end
          if fin == "m" then
            norm = norm:gsub("([345]8;2);;", "%1;")
            pen = "\27[" .. norm .. "m"
          elseif fin == "H" or fin == "f" then
            cur_r = math.max(1, nums[1] or 1)
            cur_c = math.max(1, math.min(nums[2] or 1, cols))
            last_pen = ""
          elseif fin == "G" then
            cur_c = math.max(1, math.min(nums[1] or 1, cols))
          elseif fin == "A" then
            cur_r = math.max(1, cur_r - (nums[1] or 1))
          elseif fin == "B" then
            cur_r = cur_r + (nums[1] or 1)
          elseif fin == "C" then
            cur_c = math.min(cols, cur_c + (nums[1] or 1))
          elseif fin == "D" then
            cur_c = math.max(1, cur_c - (nums[1] or 1))
          elseif fin == "E" then
            cur_r = cur_r + (nums[1] or 1)
            cur_c = 1
            last_pen = ""
          elseif fin == "F" then
            cur_r = math.max(1, cur_r - (nums[1] or 1))
            cur_c = 1
            last_pen = ""
          elseif fin == "J" then
            local mode = nums[1] or 0
            if mode == 0 then
              clear_line_segment(cur_r, cur_c, cols)
              for r = cur_r + 1, #rows do
                rows[r] = {}
              end
            elseif mode == 1 then
              for r = 1, cur_r - 1 do
                rows[r] = {}
              end
              clear_line_segment(cur_r, 1, cur_c)
            elseif mode == 2 then
              rows = {}
              cur_r, cur_c, last_pen = 1, 1, ""
            end
          elseif fin == "K" then
            local mode = nums[1] or 0
            if mode == 0 then
              clear_line_segment(cur_r, cur_c, cols)
            elseif mode == 1 then
              clear_line_segment(cur_r, 1, cur_c)
            elseif mode == 2 then
              clear_line_segment(cur_r, 1, cols)
            end
          elseif fin == "S" then
            scroll_up(nums[1] or 1)
          elseif fin == "T" then
            scroll_down(nums[1] or 1)
          elseif fin == "s" then
            saved_r, saved_c = cur_r, cur_c
          elseif fin == "u" then
            cur_r, cur_c = saved_r, saved_c
            last_pen = ""
          end
          i = j + 1
        elseif ch == "\27" and raw:sub(i + 1, i + 1):match("[()%+%$]") then
          i = i + 3
        else
          if cur_c > cols then
            cur_r = cur_r + 1
            cur_c = 1
            last_pen = ""
          end
          set_char(cur_r, cur_c, ch, pen)
          cur_c = cur_c + 1
          i = i + 1
        end
      end

      local out = {}
      for r = 1, #rows do
        local row = rows[r]
        if row then
          out[#out + 1] = table.concat(row):gsub("%s+$", "") .. "\27[0m"
        else
          out[#out + 1] = ""
        end
      end
      if #out == 0 then
        out = { raw }
      end
      vim.api.nvim_buf_set_lines(0, 0, -1, false, out)
    end

    -- 手動コマンド
    vim.api.nvim_create_user_command("WezEscFix", function()
      render_ansi_current_buf()
    end, {})

    -- SGR パラメータをパースして fg/bg 色を抽出
    local function parse_sgr(params)
      local fg, bg = nil, nil
      local nums = {}
      for n in params:gmatch("(%d+)") do
        table.insert(nums, tonumber(n))
      end
      local i = 1
      while i <= #nums do
        local n = nums[i]
        if n == 0 then
          fg, bg = nil, nil
        elseif n == 38 and nums[i + 1] == 2 then
          -- 38;2;R;G;B (truecolor foreground)
          local r, g, b = nums[i + 2], nums[i + 3], nums[i + 4]
          if r and g and b then
            fg = string.format("#%02x%02x%02x", r, g, b)
          end
          i = i + 4
        elseif n == 48 and nums[i + 1] == 2 then
          -- 48;2;R;G;B (truecolor background)
          local r, g, b = nums[i + 2], nums[i + 3], nums[i + 4]
          if r and g and b then
            bg = string.format("#%02x%02x%02x", r, g, b)
          end
          i = i + 4
        elseif n == 39 then
          fg = nil
        elseif n == 49 then
          bg = nil
        elseif n >= 30 and n <= 37 then
          -- 基本前景色（16色パレット参照）
          fg = "ANSI" .. (n - 30)
        elseif n >= 40 and n <= 47 then
          -- 基本背景色
          bg = "ANSI" .. (n - 40)
        elseif n >= 90 and n <= 97 then
          -- 明るい前景色
          fg = "ANSI" .. (n - 90 + 8)
        elseif n >= 100 and n <= 107 then
          -- 明るい背景色
          bg = "ANSI" .. (n - 100 + 8)
        end
        i = i + 1
      end
      return fg, bg
    end

    -- ANSI パレット色を実際の色に変換
    local function resolve_ansi_color(color)
      if not color then
        return nil
      end
      if color:sub(1, 1) == "#" then
        return color
      end
      -- terminal_color_N から取得
      local idx = tonumber(color:match("ANSI(%d+)"))
      if idx then
        return vim.g["terminal_color_" .. idx]
      end
      return nil
    end

    -- ANSI エスケープシーケンスをパースしてハイライトを適用（UTF-8対応）
    local function apply_ansi_highlights(bufnr, lines)
      local ns = vim.api.nvim_create_namespace("WezCaptureHL")
      vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

      local hl_cache = {}
      local hl_counter = 0

      for lnum, line in ipairs(lines) do
        local clean_parts = {}
        local highlights = {}
        local current_fg, current_bg = nil, nil
        local clean_col = 0 -- 文字単位のカラム

        local pos = 1
        while pos <= #line do
          -- ESC[ を探す
          local esc_start, esc_end, params = line:find("\27%[([%d;]*)m", pos)
          if esc_start then
            -- ESC の前のテキストを処理
            if esc_start > pos then
              local text_before = line:sub(pos, esc_start - 1)
              table.insert(clean_parts, text_before)
              local char_len = vim.fn.strchars(text_before)
              if current_fg or current_bg then
                table.insert(highlights, {
                  col_start = clean_col,
                  col_end = clean_col + char_len,
                  fg = current_fg,
                  bg = current_bg,
                })
              end
              clean_col = clean_col + char_len
            end
            -- SGR をパース
            local new_fg, new_bg = parse_sgr(params)
            if params == "0" or params == "" then
              current_fg, current_bg = nil, nil
            else
              if new_fg then
                current_fg = new_fg
              end
              if new_bg then
                current_bg = new_bg
              end
              if params:find("39") then
                current_fg = nil
              end
              if params:find("49") then
                current_bg = nil
              end
            end
            pos = esc_end + 1
          else
            -- 残りのテキスト
            local remaining = line:sub(pos)
            table.insert(clean_parts, remaining)
            local char_len = vim.fn.strchars(remaining)
            if current_fg or current_bg then
              table.insert(highlights, {
                col_start = clean_col,
                col_end = clean_col + char_len,
                fg = current_fg,
                bg = current_bg,
              })
            end
            break
          end
        end

        -- クリーンな行をバッファに設定
        local clean_line = table.concat(clean_parts)
        vim.api.nvim_buf_set_lines(bufnr, lnum - 1, lnum, false, { clean_line })

        -- ハイライトを適用
        for _, hl in ipairs(highlights) do
          local fg_color = resolve_ansi_color(hl.fg)
          local bg_color = resolve_ansi_color(hl.bg)
          if fg_color or bg_color then
            -- ハイライトグループを作成/取得
            local key = (fg_color or "") .. "|" .. (bg_color or "")
            local hl_group = hl_cache[key]
            if not hl_group then
              hl_counter = hl_counter + 1
              hl_group = "WezCapture" .. hl_counter
              local attrs = {}
              if fg_color then
                attrs.fg = fg_color
              end
              if bg_color then
                attrs.bg = bg_color
              end
              vim.api.nvim_set_hl(0, hl_group, attrs)
              hl_cache[key] = hl_group
            end
            -- 文字位置をバイト位置に変換
            local byte_start = vim.fn.byteidx(clean_line, hl.col_start)
            local byte_end = vim.fn.byteidx(clean_line, hl.col_end)
            if byte_start >= 0 and byte_end >= 0 then
              vim.api.nvim_buf_add_highlight(bufnr, ns, hl_group, lnum - 1, byte_start, byte_end)
            end
          end
        end
      end
    end

    -- ISO-8613-6 形式のエスケープシーケンスを標準形式に変換（UTF-8安全）
    local function convert_sgr_colon_to_semicolon(text)
      -- CR/CRLF を LF に統一
      text = text:gsub("\r\n", "\n"):gsub("\r", "\n")
      -- OSC シーケンス（タイトル設定など）を除去
      text = text:gsub("\27%].-\7", "")
      text = text:gsub("\27%].-\27\\", "")
      -- 文字セット切り替えシーケンス ESC ( B 等を除去
      text = text:gsub("\27[%(%)][A-Z0-9]", "")
      -- SGR シーケンス内のコロンをセミコロンに変換: 48:2::R:G:B -> 48;2;R;G;B
      text = text:gsub("(\27%[)([%d:;]+)(m)", function(esc, params, fin)
        params = params:gsub(":", ";")
        -- 38;2;;R;G;B -> 38;2;R;G;B（空サブパラメータ除去）
        params = params:gsub(";2;;", ";2;")
        return esc .. params .. fin
      end)
      return text
    end

    -- WezTerm ペインをキャプチャして表示（通常バッファ + 独自ハイライト）
    vim.api.nvim_create_user_command("WezCapture", function(opts)
      local pane_id = opts.args ~= "" and opts.args or nil
      local wezterm_path = vim.fn.exepath("wezterm")
      if wezterm_path == "" then
        wezterm_path = "/opt/homebrew/bin/wezterm"
      end
      -- スクロールバック全体を取得（-100000 から開始）
      local cmd = wezterm_path .. " cli get-text --escapes --start-line -100000"
      if pane_id then
        cmd = cmd .. " --pane-id=" .. pane_id
      end
      -- 出力を取得して変換
      local output = vim.fn.system(cmd)
      local converted = convert_sgr_colon_to_semicolon(output)
      -- 行に分割
      local lines = vim.split(converted, "\n", { plain = true })
      -- 末尾の空行を除去
      while #lines > 0 and lines[#lines] == "" do
        table.remove(lines)
      end
      -- 新しいバッファを作成
      vim.cmd("enew")
      vim.bo.buftype = "nofile"
      vim.bo.bufhidden = "wipe"
      vim.bo.swapfile = false
      -- 空の行を設定（後で上書き）
      local empty_lines = {}
      for _ = 1, #lines do
        table.insert(empty_lines, "")
      end
      vim.api.nvim_buf_set_lines(0, 0, -1, false, empty_lines)
      -- 独自のハイライト処理（UTF-8対応）
      apply_ansi_highlights(vim.api.nvim_get_current_buf(), lines)
    end, { nargs = "?", desc = "Capture WezTerm pane with ANSI colors", force = true })

    vim.api.nvim_create_user_command("BaleiaColorize", function()
      local bufnr = vim.api.nvim_get_current_buf()
      local b = ensure_baleia()
      if b then
        ---@diagnostic disable-next-line:param-type-mismatch
        b.once(bufnr)
      end
    end, { bang = true })

    vim.api.nvim_create_user_command("BaleiaLogs", function()
      local b = ensure_baleia()
      if b then
        b.logger.show()
      end
    end, { bang = true })

    -- stdin から読むとき
    vim.api.nvim_create_autocmd("StdinReadPost", {
      callback = function()
        local bufnr = vim.api.nvim_get_current_buf()

        -- filetypeが設定されるのを待つ（man関数の -c 'set ft=man' を考慮）
        vim.defer_fn(function()
          -- man ページの場合はスキップ（col -bx で処理済みのため）
          local ft = vim.api.nvim_buf_get_option(bufnr, "filetype")
          if ft == "man" then
            return
          end

          -- 元のバッファがまだ有効か確認
          if not vim.api.nvim_buf_is_valid(bufnr) then
            return
          end

          -- 現在のバッファを一時保存して処理対象のバッファに切り替え
          local current = vim.api.nvim_get_current_buf()
          vim.api.nvim_set_current_buf(bufnr)

          render_ansi_current_buf()
          local b = ensure_baleia()
          if b then
            ---@diagnostic disable-next-line:param-type-mismatch
            b.automatically(bufnr)
          end

          -- 元のバッファに戻す（異なる場合のみ）
          if current ~= bufnr and vim.api.nvim_buf_is_valid(current) then
            vim.api.nvim_set_current_buf(current)
          end
        end, 50) -- 50ms遅延して filetype 設定を待つ
      end,
    })

    -- wezescファイルタイプ用のLSP無効化
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        local bufname = vim.api.nvim_buf_get_name(args.buf)
        if bufname:match("%.wezesc$") or bufname:match("%.esc$") or bufname:match("%.ansilog$") then
          vim.schedule(function()
            vim.lsp.buf_detach_client(args.buf, args.data.client_id)
          end)
        end
      end,
    })

    -- 拡張子で読むとき
    vim.api.nvim_create_autocmd("BufReadPost", {
      pattern = { "*.wezesc", "*.esc", "*.ansilog" },
      callback = function(ctx)
        vim.bo[ctx.buf].filetype = "wezesc"
        render_ansi_current_buf()
        local b = ensure_baleia()
        if b then
          ---@diagnostic disable-next-line:param-type-mismatch
          b.automatically(ctx.buf) -- ctx.buf は bufnr
        end
      end,
    })
  end,
}
