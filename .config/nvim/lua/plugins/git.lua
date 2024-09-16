return {
  {
    "dinhhuy258/git.nvim", -- git プラグイン
    keys = {
      {
        "<leader>go",
        function()
          local status, git = pcall(require, "git")
          if status then
            git.setup({
              default_mappings = false,
              keymaps = {
                browse = "<Leader>go",
              },
            })
          end
        end,
        desc = "Browse File",
      },
    },
  },
  {
    "sindrets/diffview.nvim", -- diffview プラグイン
    config = function()
      require("diffview").setup()
      local opts = { noremap = true, silent = true, desc = "Diffview" }
      local function toggle_diffview()
        local view = require("diffview.lib").get_current_view()
        if view then
          vim.cmd("DiffviewClose")
        else
          vim.cmd("DiffviewOpen")
        end
      end
      vim.keymap.set("n", "<leader>gd", toggle_diffview, opts)
    end,
  },
}
