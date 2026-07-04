--- ANSIエスケープシーケンスを除去する
local function strip_ansi(str)
  str = str:gsub("\27%[[0-9;:?]*%a", "") -- CSI sequences (SGR, cursor, etc.)
  str = str:gsub("\27%].-\27\\", "") -- OSC sequences (ESC] ... ESC\)
  str = str:gsub("\27%].-\7", "") -- OSC sequences (ESC] ... BEL)
  str = str:gsub("\27[%(%)][A-Z0-9]", "") -- Character set designation
  return str
end

return {
  "folke/snacks.nvim",
  keys = {
    -- stylua: ignore start
    { "<leader>na", function() require("nb").add() end, desc = "nb add" },
    { "<leader>nA", function() require("nb").add_select() end, desc = "nb add (select notebook)" },
    { "<leader>ni", function() require("nb").import_image() end, desc = "nb import image" },
    { "<leader>nl", function() require("nb").link() end, desc = "nb link" },
    { "<leader>nm", function() require("nb").move() end, desc = "nb move to notebook" },
    { "<leader>nM", function() require("nb").adopt_buffer() end, desc = "nb adopt current buffer" },
    { "<leader>np", function() require("nb").pick() end, desc = "nb picker" },
    { "<leader>ng", function() require("nb").grep() end, desc = "nb grep" },
    { "<leader>nP", function() require("config.plans").picker() end, desc = "nb plans picker" },
    { "<leader>nL", function() require("config.plans").open_latest() end, desc = "nb open latest plan" },
    -- stylua: ignore end
  },
  init = function()
    require("nb").setup({
      dir = "~/src/github.com/mozumasu/nb",
      -- WezTerm のスクロールバック (.wezesc) は ANSI を除去してプレビュー
      preview = function(ctx)
        if ctx.item.file:match("%.wezesc$") then
          local lines = vim.fn.readfile(ctx.item.file)
          for i, line in ipairs(lines) do
            lines[i] = strip_ansi(line)
          end
          ctx.preview:set_lines(lines)
          return
        end
        return require("snacks").picker.preview.file(ctx)
      end,
    })

    vim.api.nvim_create_user_command("NbAdopt", function()
      require("nb").adopt_buffer()
    end, { desc = "Move current buffer into nb notebook" })
    vim.api.nvim_create_user_command("Plans", function()
      require("config.plans").picker()
    end, { desc = "Pick a plan from plansDirectory" })
    vim.api.nvim_create_user_command("PlanLatest", function()
      require("config.plans").open_latest()
    end, { desc = "Open the latest plan" })
  end,
}
