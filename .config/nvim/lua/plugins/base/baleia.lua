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

    -- 拡張子で読むとき
    vim.api.nvim_create_autocmd("BufReadPost", {
      pattern = { "*.wezesc", "*.esc", "*.ansilog" },
      callback = function(ctx)
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
