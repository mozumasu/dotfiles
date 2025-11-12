return {
  "HakonHarnes/img-clip.nvim",
  event = "VeryLazy",
  opts = {
    default = {
      -- file and directory options
      dir_path = "assets", ---@type string | fun(): string
      extension = "png", ---@type string | fun(): string
      use_absolute_path = false, ---@type boolean | fun(): boolean
      relative_to_current_file = true, ---@type boolean | fun(): boolean

      -- prompt options
      prompt_for_file_name = true, ---@type boolean | fun(): boolean
      show_dir_path_in_prompt = false, ---@type boolean | fun(): boolean
    },
  },
  keys = {
    -- suggested keymap
    { "<leader>P", "<cmd>PasteImage<cr>", desc = "Paste image from system clipboard" },
  },
}
