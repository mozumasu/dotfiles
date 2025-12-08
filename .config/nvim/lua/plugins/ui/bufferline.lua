return {
  "akinsho/bufferline.nvim",
  opts = function(_, opts)
    local nb = require("config.nb")
    opts.options = opts.options or {}
    opts.options.name_formatter = function(buf)
      local title = nb.get_title(buf.path)
      return title or buf.name
    end
  end,
}
