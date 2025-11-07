return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    config = function(_, opts)
      require("snacks").setup(opts)

      -- Auto show image on cursor hold
      vim.api.nvim_create_autocmd("CursorHold", {
        group = vim.api.nvim_create_augroup("snacks_image_hover", { clear = true }),
        pattern = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.md", "*.markdown" },
        callback = function()
          if Snacks and Snacks.image and Snacks.image.hover then
            -- Safely call hover, ignore errors if no image at cursor
            pcall(Snacks.image.hover)
          end
        end,
      })

      -- Optional: Reduce updatetime for faster hover (default is 4000ms)
      vim.opt.updatetime = 100 -- Show hover after 1 second
    end,
    keys = {
      {
        "<leader>mp",
        ft = { "png", "markdown" },
        function()
          Snacks.image.hover()
        end,
        desc = "Preview image/math formula under cursor (manual)",
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
          inline = true,
          -- render the image in a floating window
          -- only used if `opts.inline` is disabled
          float = false,
          max_width = 80,
          max_height = 40,
        },
      },
      picker = {
        sources = {
          recent = {
            transform = function(item, ctx)
              -- Add title to nb note files for searching
              if item.file and item.file:match("/nb/[^/]+/.*.md") then
                local file = io.open(item.file, "r")
                if file then
                  local first_line = file:read("*l")
                  file:close()

                  -- Extract heading from the first line
                  local heading = first_line and first_line:match("^#%s+(.+)")
                  if heading then
                    -- Store title for display and add to searchable text
                    item.nb_title = heading
                    -- Add title to text field so it's searchable
                    item.text = item.text .. " " .. heading
                  end
                end
              end
              return item
            end,
            format = function(item, picker)
              -- nb note files (both home and work directories)
              if item.file and item.file:match("/nb/[^/]+/.*.md") then
                -- Use cached title if available
                if item.nb_title then
                  -- Return formatted text with note icon and title only
                  return {
                    { "📝 ", "TelescopeResultsSpecialComment" },
                    { item.nb_title, "TelescopeResultsIdentifier" },
                  }
                end

                -- Fallback: read file if title not cached
                local file = io.open(item.file, "r")
                if file then
                  local first_line = file:read("*l")
                  file:close()

                  -- Extract heading from the first line
                  local heading = first_line and first_line:match("^#%s+(.+)")
                  if heading then
                    -- Return formatted text with note icon and title only
                    return {
                      { "📝 ", "TelescopeResultsSpecialComment" },
                      { heading, "TelescopeResultsIdentifier" },
                    }
                  end
                end
              end

              -- Fall back to standard file formatter
              return require("snacks.picker").format.file(item, picker)
            end,
          },
        },
      },
    },
  },
}
