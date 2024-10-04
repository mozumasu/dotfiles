return {
  {
    "voldikss/vim-translator",
    cmd = { "TranslateW", "TranslateW --target_lang=en" },
    keys = {
      { "<leader>t", "", desc = "Translate" },
      { "<leader>tj", "<cmd>TranslateW<CR>", mode = "n", desc = "to Japanese" },
      { "<leader>tj", ":'<,'>TranslateW<CR>", mode = "v", desc = "to Japanese" },
      { "<leader>te", "<cmd>TranslateW --target_lang=en<CR>", mode = "n", desc = "to English" },
      { "<leader>te", ":'<,'>TranslateW --target_lang=en<CR>", mode = "v", desc = "to English" },
    },
    config = function()
      vim.g.translator_target_lang = "ja"
      vim.g.translator_default_engines = { "google" }
      vim.g.translator_history_enable = true
    end,
  },
  {
    "potamides/pantran.nvim",
    keys = {
      { "<leader>tw", "<cmd>Pantran<CR>", mode = "n", desc = "Show Translate Window" },
    },
    config = function()
      require("pantran").setup({
        default_engine = "google",
        engines = {
          google = {
            fallback = {
              default_source = "auto",
              default_target = "ja",
            },
            -- NOTE: must set `DEEPL_AUTH_KEY` env-var
            -- deepl = {
            --   default_source = "",
            --   default_target = "",
            -- },
          },
        },
        ui = {
          width_percentage = 0.8,
          height_percentage = 0.8,
        },
        window = {
          title_border = { "⭐️ ", " ⭐️    " }, -- for google
          window_config = { border = "rounded" },
        },
        controls = {
          mappings = {
            edit = {
              -- normal mode mappings
              n = {
                ["j"] = "gj",
                ["k"] = "gk",
              },
              -- insert mode mappings
              i = {
                ["<C-y>"] = false,
                ["<C-a>"] = require("pantran.ui.actions").yank_close_translation,
              },
            },
            -- Keybindings here are used in the selection window.
            select = {},
          },
        },
      })
    end,
  },
}
