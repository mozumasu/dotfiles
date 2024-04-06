local plugins = {
	{
		"nvim-treesitter/nvim-treesitter",
		event = { "BufNewFile", "BufReadPre" },
	},
	{
		"JohnnyMorganz/StyLua",
	},
	{
		"dense-analysis/ale",
		config = function()
			-- Configuration goes here.
			local g = vim.g

			g.ale_ruby_rubocop_auto_correct_all = 1

			g.ale_linters = {
				ruby = { "rubocop", "ruby" },
				lua = { "lua_language_server" },
			}
		end,
	},
	{
		"neoclide/coc.nvim",
		branch = "release",
	},
	{
		"dinhhuy258/git.nvim",
		keys = {
			"<leader>gh",
		},
	},
	{
		"rmehri01/onenord.nvim",
		event = { "VimEnter" },
		priority = 1000,
		config = function()
			require("extensions.onenord")
		end,
	},
	{
		"nvim-lualine/lualine.nvim",
		event = { "VimEnter" },
		config = function()
			require("lualine").setup({
        options = {
          globalstatus = true,
        }
      })
		end,
	},
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre" },
	},
	{
		"nvim-telescope/telescope.nvim",
		keys = {
			"<leader>ff",
			"<leader>fg",
			"<leader>fb",
			"<leader>fh",
		},
		tag = "0.1.4",
		config = function()
			require("extensions.telescope")
		end,
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		},
	},
	{
		"petertriho/nvim-scrollbar",
		event = { "BufNewFile", "BufReadPre" },
	},
	{
		"nvim-tree/nvim-tree.lua",
		keys = {
			"<leader>ex",
		},
		config = function()
			require("extensions.nvim-tree")
		end,
		dependencies = {
			"nvim-tree/nvim-web-devicons",
			"nvim-telescope/telescope.nvim",
		},
	},
	{
		"zbirenbaum/copilot-cmp",
		event = { "InsertEnter" },
		config = function()
			require("copilot_cmp").setup()
		end,
		dependencies = {
			"hrsh7th/nvim-cmp",
			"zbirenbaum/copilot.lua",
		},
	},
	{
		"iamcco/markdown-preview.nvim",
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
		ft = { "markdown" },
		build = function()
			vim.fn["mkdp#util#install"]()
		end,
	},
	{
		"zbirenbaum/copilot.lua",
		event = { "InsertEnter" },
		config = function()
			require("extensions.copilot")
		end,
	},
}
local opts = {
	checker = {
		enabled = true,
	},
	preformance = {
		cache = {
			enabled = true,
		},
		reset_packpath = true,
		rtp = {
			reset = true,
			paths = {},
			disabled_plugins = {
				"gzip",
				"matchit",
				-- "matchparen",
				-- "netrwPlugin",
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
			},
		},
	},
}

-- Lazy.nvim Installation
-- https://github.com/folke/lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)
require("lazy").setup(plugins, opts)
