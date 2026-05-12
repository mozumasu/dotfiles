return {
  {
    "michaelb/sniprun",
    branch = "master",
    build = "sh install.sh",
    cmd = { "SnipRun", "SnipInfo", "SnipClose", "SnipReset", "SnipReplMemoryClean", "SnipLive" },
    keys = {
      { "<leader><CR>", "<cmd>SnipRun<cr>", desc = "SnipRun line" },
      { "<leader><CR>", "<Plug>SnipRun", mode = "v", desc = "SnipRun selection" },
      { "<leader><CR>R", "<cmd>%SnipRun<cr>", desc = "SnipRun file" },
      { "<leader><CR>q", "<cmd>SnipClose<cr>", desc = "SnipRun close" },
    },
    opts = {
      display = { "VirtualTextOk", "TempFloatingWindow" },
      display_options = {
        notification_timeout = 5,
      },
      live_mode_toggle = "off",
      selected_interpreters = {},
      repl_enable = {},
    },
    config = function(_, opts)
      require("sniprun").setup(opts)
    end,
  },
}
