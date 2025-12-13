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
      dashboard = {
        preset = {
          keys = {
            { icon = " ", key = "f", desc = "Find File", action = function()
              local cwd = vim.fn.getcwd()
              local hidden = cwd:match("dotfiles$") ~= nil
              Snacks.picker.files({ cwd = cwd, hidden = hidden })
            end },
            { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = " ", key = "g", desc = "Find Text", action = function()
              local cwd = vim.fn.getcwd()
              local hidden = cwd:match("dotfiles$") ~= nil
              Snacks.picker.grep({ cwd = cwd, hidden = hidden })
            end },
            { icon = " ", key = "r", desc = "Recent Files", action = function() Snacks.picker.recent() end },
            { icon = " ", key = "c", desc = "Config", action = function() Snacks.picker.files({ cwd = vim.fn.stdpath("config"), hidden = true }) end },
            { icon = " ", key = "s", desc = "Restore Session", section = "session" },
            { icon = "󰒲 ", key = "x", desc = "Lazy Extras", action = ":LazyExtras" },
            { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
      },
      image = {
        enabled = true,
        -- nb の --original URL形式を実際のファイルパスに変換
        resolve = function(file, src)
          -- http://localhost:6789/--original/{notebook}/{filename} 形式を検出
          local notebook, filename = src:match("http://localhost:6789/%-%-original/([^/]+)/(.+)$")
          if notebook and filename then
            local nb = require("config.nb")
            return nb.get_nb_dir() .. "/" .. notebook .. "/" .. filename
          end
          return nil
        end,
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
        win = {
          input = {
            keys = {
              ["h"] = { "toggle_hidden", mode = { "n" } },
              ["I"] = { "toggle_ignored", mode = { "n" } },
            },
          },
        },
      },
    },
  },
}
