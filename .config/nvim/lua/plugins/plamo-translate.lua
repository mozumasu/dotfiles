return {
  dir = "~/src/github.com/mozumasu/plamo-translate.nvim",
  name = "plamo-translate.nvim",
  cmd = { "PlamoTranslate", "PlamoTranslateReplace", "PlamoTranslateLine", "PlamoTranslateWord" },
  keys = {
    -- Normal mode: interactive window
    { "<leader>tt", "<cmd>PlamoTranslate<cr>", mode = "n", desc = "Translate text (interactive)" },
    -- Visual mode: translate selection (:'<,'> preserves selection)
    { "<leader>tt", ":'<,'>PlamoTranslate<cr>", mode = "v", desc = "Translate selected text" },
    { "<leader>tr", ":'<,'>PlamoTranslateReplace<cr>", mode = "v", desc = "Replace with translation" },
    -- Normal mode: line and word
    { "<leader>tl", "<cmd>PlamoTranslateLine<cr>", mode = "n", desc = "Translate current line" },
    { "<leader>tw", "<cmd>PlamoTranslateWord<cr>", mode = "n", desc = "Translate word under cursor" },
  },
  config = function()
    require("plamo-translate").setup({
      cli = {
        cmd = { "plamo-translate", "--no-stream" }, -- CLI command
        from = "English", -- Source language
        to = "Japanese", -- Target language
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
            width = 0.5, -- Smaller, less intrusive
            height = 0.1,
          },
          right = {
            width = 0.4, -- Sidebar width
            height = 1.0, -- Full height
          },
        },
      },
    })
  end,
}
