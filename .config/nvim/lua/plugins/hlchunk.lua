return {
  "shellRaining/hlchunk.nvim",
  lazy = true,
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    chunk = {
      enable = true,
      chars = {
        horizontal_line = "─",
        vertical_line = "│",
        left_top = "╭",
        left_bottom = "╰",
        right_arrow = ">",
      },
      style = "#806d9c",
    },
  },
}
