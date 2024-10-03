return {
  "pwntester/octo.nvim",
  cmd = "Octo",
  event = "BufReadCmd octo://*",
  opts = function(_, opts)
    opts.enable_builtin = true
    opts.default_to_projects_v2 = true
    opts.default_merge_method = "squash"

    vim.treesitter.language.register("markdown", "octo")

    if LazyVim.has("telescope.nvim") then
      opts.picker = "telescope"
    elseif LazyVim.has("fzf-lua") then
      opts.picker = "fzf-lua"
    else
      LazyVim.error("`octo.nvim` requires `telescope.nvim` or `fzf-lua`")
    end

    -- Keep some empty windows in sessions
    vim.api.nvim_create_autocmd("ExitPre", {
      group = vim.api.nvim_create_augroup("octo_exit_pre", { clear = true }),
      callback = function(ev)
        local keep = { "octo" }
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          local buf = vim.api.nvim_win_get_buf(win)
          if vim.tbl_contains(keep, vim.bo[buf].filetype) then
            vim.bo[buf].buftype = "" -- set buftype to empty to keep the window
          end
        end
      end,
    })
  end,
  keys = {
    { "<leader>gi", "<cmd>Octo issue list<CR>", desc = "List Open Issues (Octo)" },
    { "<leader>gI", "<cmd>Octo issue search<CR>", desc = "List All Issues (Octo)" },
    { "<leader>gp", "<cmd>Octo pr list<CR>", desc = "List Open PRs (Octo)" },
    { "<leader>gP", "<cmd>Octo pr search<CR>", desc = "List All PRs (Octo)" },
    { "<leader>gr", "<cmd>Octo repo list<CR>", desc = "List Repos (Octo)" },
    -- { "<leader>gS", "<cmd>Octo search<CR>", desc = "Search (Octo)" },
    -- { "<leader>a", "", desc = "+assignee (Octo)", ft = "octo" },
    -- { "<leader>c", "", desc = "+comment/code (Octo)", ft = "octo" },
    -- { "<leader>l", "", desc = "+label (Octo)", ft = "octo" },
    { "<leader>i", "", desc = "+issue (Octo)", ft = "octo" },
    { "<leader>il", "<cmd>Octo issue list<CR>", desc = "List issue" },
    { "<leader>ia", "<cmd>Octo issue create<CR>", desc = "Add issue" },
    -- { "<leader>ie", "<cmd>Octo issue edit<CR>", desc = "Edit issue" },
    {
      "<leader>ie",
      function()
        local issue_number = vim.fn.input("Issue Number: ")
        require("octo.commands").edit_issue(issue_number)
      end,
      desc = "Edit issue",
    },
    { "<leader>ic", "<cmd>Octo issue close<CR>", desc = "Close issue" },

    -- { "<leader>r", "", desc = "+react (Octo)", ft = "octo" },
    -- { "<leader>p", "", desc = "+pr (Octo)", ft = "octo" },
    -- { "<leader>v", "", desc = "+review (Octo)", ft = "octo" },
    -- { "@", "@<C-x><C-o>", mode = "i", ft = "octo", silent = true },
    -- { "#", "#<C-x><C-o>", mode = "i", ft = "octo", silent = true },
  },
}
