return {
  {
    "folke/tokyonight.nvim",
    enable = false,
    lazy = false, -- If it is not loaded at startup, it will not be added to the ui list.
    opts = { style = "moon" },
  },
  {
    "thesimonho/kanagawa-paper.nvim",
    -- lazy = false,
    -- priority = 1000,
    opts = {
      transparent = true,
      wezterm = {
        enabled = false,
        -- neovim will write the theme name to this file
        -- wezterm will read from this file to know which theme to use
        path = (os.getenv("TEMP") or "/tmp") .. "/nvim-theme",
      },
    },
  },
  {
    "zenbones-theme/zenbones.nvim",
    -- Optionally install Lush. Allows for more configuration or extending the colorscheme
    -- If you don't want to install lush, make sure to set g:zenbones_compat = 1
    -- In Vim, compat mode is turned on as Lush only works in Neovim.
    dependencies = "rktjmp/lush.nvim",
    -- lazy = false,
    -- priority = 1000,
    -- opts = { transparent_background = true },
    -- you can set set configuration options here
    config = function()
      -- vim.g.zenbones_darken_comments = 45
      vim.g.zenbones_transparent_background = true
      vim.g.zenbones_lightness = "bright"
      vim.g.zenbones_darkness = "stark"
      vim.g.zenbones_darken_noncurrent_window = false
      vim.g.zenbones_lighten_noncurrent_window = true
      vim.g.zenbones_solid_float_border = true
      -- vim.cmd.colorscheme("zenbones")
    end,
  },
}
