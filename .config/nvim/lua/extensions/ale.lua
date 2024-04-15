local g = vim.g

g.ale_ruby_rubocop_auto_correct_all = 1

-- linterの設定
vim.g.ale_linters = {
	javascript = { "eslint" },
	javascriptreact = { "eslint" },
	typescript = { "eslint" },
	typescriptreact = { "eslint" },
	vue = { "eslint" },
	svelte = { "eslint" },
	html = { "htmlhint" },
	css = { "stylelint" },
	scss = { "stylelint" },
	php = { "phpcs" },
}

-- formatterの設定
vim.g.ale_fixers = {
	["*"] = { "remove_trailing_lines", "trim_whitespace" },
	["rust"] = { "rustfmt" },
	javascript = { "prettier", "eslint" },
	json = { "prettier", "eslint" },
	javascriptreact = { "prettier", "eslint" },
	typescript = { "prettier", "eslint" },
	typescriptreact = { "prettier", "eslint" },
	vue = { "prettier", "eslint" },
	svelte = { "prettier", "eslint" },
	css = { "prettier", "stylelint" },
	scss = { "prettier", "stylelint" },
	go = { "trim_whitespace", "remove_trailing_lines", "goimports", "gofmt" },
	lua = { "stylua" },
	html = { "prettier" },
	php = { "phpcbf" },
}

-- ファイル保存時に実行
vim.g.ale_fix_on_save = 1

-- ローカルの設定ファイルを考慮する
vim.g.ale_javascript_prettier_use_local_config = 1
