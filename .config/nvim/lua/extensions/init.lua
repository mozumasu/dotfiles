local plugins = {
	-- ハイライト
	{
		"nvim-treesitter/nvim-treesitter",
		event = { "BufNewFile", "BufReadPre" },
	},
	-- フォーマッターとリンター
	{
		"JohnnyMorganz/StyLua",
	},
	{
		"dense-analysis/ale",
		config = function()
			require("extensions.ale")
		end,
	},
	-- 補完や定義ジャンプなど
	{
		"neoclide/coc.nvim",
		branch = "release",
	},
	-- diffとblame、コードのGitHubページ表示
	{
		"dinhhuy258/git.nvim",
		event = { "VimEnter" },
		config = function()
			require("extensions.git-nvim")
		end,
	},
	-- ファイラー
	{
		"lambdalisue/fern.vim",
		event = { "VimEnter" },
		config = function()
			require("extensions.fern")
		end,
		dependencies = {
			"lambdalisue/fern-git-status.vim",
			-- ステージへの追加と解除
			"lambdalisue/fern-mapping-git.vim",
			-- フォント表示
			"lambdalisue/nerdfont.vim",
			"lambdalisue/fern-renderer-nerdfont.vim",
			-- ファイルツリーのアイコンの色を設定
			"lambdalisue/glyph-palette.vim",
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
	-- ステータスライン
	{
		"nvim-lualine/lualine.nvim",
		event = { "VimEnter" },
		config = function()
			require("lualine").setup({
				options = {
					globalstatus = true,
				},
			})
		end,
	},
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre" },
	},
	-- ファイル検索
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
	-- copilot
	{
		"zbirenbaum/copilot.lua",
		event = { "InsertEnter" },
		config = function()
			require("extensions.copilot")
		end,
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
		"hrsh7th/nvim-cmp",
		event = { "VimEnter" },
		config = function()
			require("extensions.nvim-cmp")
		end,
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-cmdline",
			"hrsh7th/cmp-path",
			"onsails/lspkind-nvim",
			"L3MON4D3/LuaSnip",
		},
	},
	-- コメントアウト
	{
		"numToStr/Comment.nvim",
		opts = {
			-- add any options here
		},
		lazy = false,
	},
	{
		"mattn/emmet-vim",
		ft = { "html", "css", "javascript", "typescript", "php", "vue", "svelte", "markdown" },
		config = function()
			require("extensions.emmet")
		end,
	},
	-- mdプレビュー
	{
		"iamcco/markdown-preview.nvim",
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
		ft = { "markdown" },
		build = function()
			vim.fn["mkdp#util#install"]()
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
