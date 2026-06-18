return {
  "mozumasu/plamo-translate.nvim",
  dir = vim.fn.expand("~/src/github.com/mozumasu/plamo-translate.nvim"),
  cmd = {
    "PlamoTranslate",
    "PlamoTranslateReplace",
    "PlamoTranslateLine",
    "PlamoTranslateWord",
    "PlamoTranslateBuffer",
    "PlamoTranslateBufferReplace",
    "PlamoTranslateComments",
    "PlamoTranslateCommentsClear",
    "PlamoTranslateCommentsToggle",
  },
  keys = {
    -- Normal mode: interactive window
    { "<leader>tt", "<cmd>PlamoTranslate<cr>", mode = "n", desc = "Translate text (interactive)" },
    -- Visual mode: translate selection (:'<,'> preserves selection)
    { "<leader>tt", ":'<,'>PlamoTranslate<cr>", mode = "v", desc = "Translate selected text" },
    { "<leader>tr", ":'<,'>PlamoTranslateReplace<cr>", mode = "v", desc = "Replace with translation" },
    -- Normal mode: line and word
    { "<leader>tl", "<cmd>PlamoTranslateLine<cr>", mode = "n", desc = "Translate current line" },
    { "<leader>tw", "<cmd>PlamoTranslateWord<cr>", mode = "n", desc = "Translate word under cursor" },
    -- Normal mode: buffer
    { "<leader>tb", "<cmd>PlamoTranslateBuffer<cr>", mode = "n", desc = "Translate entire buffer (split)" },
    { "<leader>tB", "<cmd>PlamoTranslateBufferReplace<cr>", mode = "n", desc = "Replace buffer with translation" },
    -- Normal mode: comment virtual text
    { "<leader>tv", "<cmd>PlamoTranslateCommentsToggle<cr>", mode = "n", desc = "Toggle comment translations" },
  },
  config = function()
    require("plamo-translate").setup({
      cli = {
        cmd = { "plamo-translate", "--no-stream" }, -- CLI command
        from = "Auto", -- Source language
        to = "Auto", -- Target language
      },
      window = {
        position = "cursor", -- "center" | "cursor" | "right"
        border = "rounded", -- "single" | "double" | "rounded" | "solid" | "shadow"
        wrap = true, -- Wrap long lines
        title = " Translation ",
        title_pos = "center", -- "left" | "center" | "right"
        positions = {
          center = {
            width = 0.8, -- 80% of screen width
            height = 0.6, -- 60% of screen height
          },
          cursor = {
            width = 0.7, -- Smaller, less intrusive
            height = 0.1,
          },
          right = {
            width = 0.4, -- Sidebar width
            height = 1.0, -- Full height
          },
        },
      },
    })

    -- Give the translation popup a solid background even though we
    -- keep NormalFloat globally transparent in autocmds.lua.
    local function apply_highlights()
      vim.api.nvim_set_hl(0, "PlamoTranslateNormal", { link = "Pmenu", default = true })
      vim.api.nvim_set_hl(0, "PlamoTranslateBorder", { link = "Pmenu", default = true })
      vim.api.nvim_set_hl(0, "PlamoTranslateTitle", { link = "Title", default = true })
    end
    apply_highlights()

    local group = vim.api.nvim_create_augroup("PlamoTranslateOpaque", { clear = true })
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = group,
      callback = apply_highlights,
    })

    local wh = table.concat({
      "Normal:PlamoTranslateNormal",
      "NormalFloat:PlamoTranslateNormal",
      "FloatBorder:PlamoTranslateBorder",
      "FloatTitle:PlamoTranslateTitle",
    }, ",")

    vim.api.nvim_create_autocmd("WinNew", {
      group = group,
      callback = function()
        vim.schedule(function()
          local win = vim.api.nvim_get_current_win()
          if not vim.api.nvim_win_is_valid(win) then return end
          local cfg = vim.api.nvim_win_get_config(win)
          if cfg.relative == "" then return end

          local title = cfg.title
          if type(title) == "table" then
            local s = ""
            for _, part in ipairs(title) do
              s = s .. (part[1] or "")
            end
            title = s
          end
          if type(title) == "string" and title:find("Translation", 1, true) then
            vim.wo[win].winhighlight = wh
          end
        end)
      end,
    })
  end,
}
