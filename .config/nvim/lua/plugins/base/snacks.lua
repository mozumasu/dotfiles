return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    keys = {
      {
        "<leader>mp",
        ft = { "png", "markdown" },
        function()
          Snacks.image.hover()
        end,
        desc = "Preview math formula under cursor",
      },
      {
        "<leader>p",
        function()
          Snacks.picker.pickers()
        end,
      },
      {
        "<space>fh",
        function()
          Snacks.picker.help({
            win = {
              input = { keys = {
                ["<CR>"] = { "edit_vsplit", mode = { "i", "n" } },
              } },
            },
          })
        end,
        desc = "Picker: help pages",
      },
    },
    ---@type snacks.Config
    opts = {
      scroll = { enabled = false },
      image = {
        enabled = true,
        doc = {
          -- enable image viewer for documents
          -- a treesitter parser must be available for the enabled languages.
          -- supported language injections: markdown, html
          enabled = true,
          -- render the image inline in the buffer
          -- if your env doesn't support unicode placeholders, this will be disabled
          -- takes precedence over `opts.float` on supported terminals
          inline = false,
          -- render the image in a floating window
          -- only used if `opts.inline` is disabled
          float = false,
          max_width = 80,
          max_height = 40,
        },
      },
      picker = {
        sources = {
          buffers = {
            format = function(item, picker)
              -- nb note files
              if item.file and item.file:match("/nb/home/.*.md") then
                local file = io.open(item.file, "r")
                if file then
                  local first_line = file:read("*l")
                  file:close()
                  
                  -- Extract heading from the first line
                  local heading = first_line and first_line:match("^#%s+(.+)")
                  if heading then
                    -- Return formatted text with note title only
                    return {
                      { heading, "TelescopeResultsIdentifier" }
                    }
                  end
                end
              end
              
              -- Use default format for other files
              return picker.format.format(item, picker, "buffer")
            end
          }
        }
      },
    },
  },
}
