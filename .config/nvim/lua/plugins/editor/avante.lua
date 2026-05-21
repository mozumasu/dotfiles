return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  version = false, -- set this if you want to always pull the latest change
  opts = {
    provider = "copilot",
  },
  keys = { "<leader>a", desc = "Avante" },
  -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
  build = "make",
  -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
  dependencies = {
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    --- The below dependencies are optional,
    "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
    "zbirenbaum/copilot.lua", -- for providers='copilot'
    {
      -- support for image pasting
      "HakonHarnes/img-clip.nvim",
    },
    {
      -- Make sure to set this up properly if you have lazy=true
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        -- octo は octo.lua 側で先読みロード + markdown parser register して描画する。
        -- ft には octo を入れない: FileType=octo 遅延ロードが octo の非同期バッファ
        -- 生成中に発火し race (Invalid buffer id) を誘発するため。
        file_types = { "markdown", "Avante", "octo" },
      },
      ft = { "markdown", "Avante" },
    },
  },
}
