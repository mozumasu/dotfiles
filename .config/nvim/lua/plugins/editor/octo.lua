return {
  "pwntester/octo.nvim",
  keys = {
    {
      "<leader>gP",
      "<cmd>OctoSearchProject<CR>",
      desc = "Search Project Issues (with completion)",
    },
  },
  config = function(_, opts)
    -- octo://バッファはGitHub APIが実態のため、スワップファイル不要
    -- BufReadCmd: octo.nvimが内部でバッファ読み込みを行う際に発火
    vim.api.nvim_create_autocmd("BufReadCmd", {
      pattern = "octo://*",
      callback = function()
        vim.opt_local.swapfile = false
      end,
    })
    -- render-markdown.nvim が octo バッファを装飾できるよう
    -- octo filetype に markdown treesitter parser を割り当てる
    vim.treesitter.language.register("markdown", "octo")
    require("octo").setup(opts)

    -- render-markdown を octo ロード時(=安全なタイミング)に先読みしておく。
    -- FileType=octo での遅延ロードを避けることで、ピッカーのプレビューバッファ
    -- 生成中に同期ロードがストールして起きる race (Invalid buffer id) を防ぐ。
    pcall(function()
      require("lazy").load { plugins = { "render-markdown.nvim" } }
    end)
  end,
}
