local cmp = require("cmp")
local map = cmp.mapping
local act = require("extensions.nvim-cmp-actions")
local luasnip = require("luasnip")

local map = cmp.mapping

local has_words_before = function()
	local line, col = unpack(vim.api.nvim_win_get_cursor(0))
	return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

cmp.setup({
	mapping = map.preset.insert {
		["<C-d>"] = map.scroll_docs(-4),
		["<C-f>"] = map.scroll_docs(4),
		["<C-Space>"] = map.complete(),
		["<C-e>"] = map.abort(),
		["<CR>"] = map.confirm({
			select = true,
      behavior = cmp.ConfirmBehavior.Replace,
		}),
		["<Tab>"] = map(act.tab, { "i", "s" }),
		["<S-Tab>"] = map(act.shift_tab, { "i", "s" }),
	},
	sources = cmp.config.sources({
		{ name = "nvim_lsp" },
		{ name = "luasnip" },
		{ name = "copilot" },
		{ name = "buffer" },
		{ name = "path" },
	}),
	snippet = {
		expand = function(args)
			luasnip.lsp_expand(args.body)
		end,
	},
	formatting = {
		format = require("lspkind").cmp_format({
			mode = "symbol",
			preset = "codicons",
			symbol_map = { Copilot = "" },
		}),
	},
})

cmp.setup.cmdline(":", {
	mapping = cmp.mapping.preset.cmdline(),
	sources = cmp.config.sources({
		{ name = "cmdline" },
		{ name = "path" },
	}),
})

cmp.setup.cmdline({ "/", "?" }, {
	mapping = cmp.mapping.preset.cmdline(),
	sources = cmp.config.sources({
		{
			name = "buffer",
			option = {
				keyword_pattern = [[\k\+]],
			},
		},
	}),
})
