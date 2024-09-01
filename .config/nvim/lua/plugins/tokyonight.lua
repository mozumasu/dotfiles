return {
  {
    "folke/tokyonight.nvim",
    lazy = false, -- 起動時に読み込まないと、uiリストに追加されない
    opts = { style = "moon" },
  },
  -- 起動時のデフォルト設定に使用したい場合は下記を有効化する
  -- {
  --   "LazyVim/LazyVim",
  --   opts = {
  --     colorscheme = "tokyonight",
  --   },
  -- },
}
