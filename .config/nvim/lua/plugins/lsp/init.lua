return {
  -- Disable markdownlint (use rumdl instead via CLI)
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        markdown = {},
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    keys = {
      {
        "<leader>cD",
        function()
          local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
          local diagnostics = vim.diagnostic.get(0, { lnum = lnum })
          if #diagnostics == 0 then return end

          local messages = {}
          for _, d in ipairs(diagnostics) do
            table.insert(messages, string.format("[%s] %s", d.source or "Unknown", d.message))
          end
          local text = table.concat(messages, "\n")

          require("plamo-translate.translate").translate(text, function(result, err)
            if err or not result then
              vim.diagnostic.open_float()
              return
            end
            require("plamo-translate.ui").show(result, { position = "cursor" })
          end)
        end,
        desc = "Line Diagnostics (Translated)",
      },
      {
        "<leader>cK",
        function()
          local params = vim.lsp.util.make_position_params(0, "utf-16")
          vim.lsp.buf_request(0, "textDocument/hover", params, function(_, result)
            if not result or not result.contents then
              vim.notify("No hover info", vim.log.levels.INFO)
              return
            end
            local lines = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
            if vim.tbl_isempty(lines) then
              vim.notify("No hover info", vim.log.levels.INFO)
              return
            end
            local text = table.concat(lines, "\n")

            require("plamo-translate.translate").translate(text, function(translated, err)
              if err or not translated then
                vim.lsp.buf.hover()
                return
              end

              -- Size the popup to the translated content so short hovers
              -- stay compact and long docs are readable.
              local out_lines = vim.split(translated, "\n", { plain = true })
              local max_w = 0
              for _, l in ipairs(out_lines) do
                local w = vim.fn.strdisplaywidth(l)
                if w > max_w then max_w = w end
              end
              local screen_w = vim.o.columns
              local screen_h = vim.o.lines
              local width_ratio = math.min(0.8, math.max(0.3, (max_w + 4) / screen_w))
              local height_ratio = math.min(0.6, math.max(0.15, (#out_lines + 2) / screen_h))

              require("plamo-translate.ui").show(translated, {
                position = "cursor",
                positions = { cursor = { width = width_ratio, height = height_ratio } },
              })
            end)
          end)
        end,
        desc = "Hover (Translated)",
      },
    },
    opts = {
      diagnostics = {
        virtual_text = {
          format = function(diagnostic)
            -- Add lsp server name to message
            return string.format("%s (%s)", diagnostic.message, diagnostic.source or "Unknown")
          end,
        },
        float = { border = "rounded" },
      },
      inlay_hints = { enabled = false },
    },
  },
  {
    "saghen/blink.cmp",
    opts = {
      completion = {
        menu = {
          border = "rounded",
        },
        documentation = {
          window = {
            border = "rounded",
          },
        },
      },
      keymap = {
        -- preset = "none",
        ["<CR>"] = {}, -- Do not use enter to confirm completion
      },
      sources = {
        default = {
          cmdline = {}, -- Disable cmdline completions (conflicts with Snacks picker)
        },
      },
    },
  },
}
