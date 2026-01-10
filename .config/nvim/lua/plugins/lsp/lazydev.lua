return {
  -- Type definitions and completion support for Lua development
  {
    "folke/lazydev.nvim",
    ft = "lua",
    cmd = "LazyDev",
    opts = {
      library = {
        -- Neovim関連
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "LazyVim", words = { "LazyVim" } },
        { path = "snacks.nvim", words = { "Snacks" } },
        { path = "lazy.nvim", words = { "LazyVim" } },
        -- WezTerm型定義サポート
        { path = "wezterm-types", mods = { "wezterm" } },
      },
    },
  },
  -- WezTerm type definition library
  {
    "justinsgithub/wezterm-types",
    lazy = true,
  },
  -- Add lazydev integration to blink.cmp
  {
    "saghen/blink.cmp",
    opts = {
      sources = {
        per_filetype = {
          lua = { inherit_defaults = true, "lazydev" },
        },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            score_offset = 100, -- Display with higher priority than LSP
          },
        },
      },
    },
  },
}
