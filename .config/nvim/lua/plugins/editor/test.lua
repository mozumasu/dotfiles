return {
  {
    "nvim-neotest/neotest",
    cmd = "Neotest",
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require("neotest").setup({
        adapters = {
          require("neotest-plenary"),
        },
      })
    end,
  },
  { "nvim-lua/plenary.nvim" },
  { "nvim-neotest/neotest-plenary" },
  { "nvim-neotest/nvim-nio" },
}
