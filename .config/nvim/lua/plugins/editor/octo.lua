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
    require("octo").setup(opts)
  end,
}
