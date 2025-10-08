return {
  "akinsho/bufferline.nvim",
  opts = {
    options = {
      name_formatter = function(buf)
        -- Detect nb repository note files
        if buf.path:match("/nb/.*%.md$") then
          local file = io.open(buf.path, "r")
          if not file then
            return
          end
          local first_line = file:read("*l")
          file:close()

          -- Check if file is empty or first line is nil
          if not first_line then
            return
          end

          -- Extract heading from the first line
          local heading = first_line:match("^#%s+(.+)")
          if heading then
            return heading
          end
        end
        -- Return default filename
      end,
    },
  },
}

