return {
  {
    "vim-skk/skkeleton",
    dependencies = { "vim-denops/denops.vim" },
  },
  {
    "delphinus/skkeleton_indicator.nvim",
    dependencies = { "vim-skk/skkeleton" },
    config = true,
  },
}
