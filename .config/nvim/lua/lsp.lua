-- control + n 下に移動
-- control + p 上に移動
-- 
-- silent・・・コマンドラインへの出力を抑制する
-- <C-u>hoge<cr>・・・特殊なキーのマッピング
-- https://thinca.hatenablog.com/entry/20100205/1265307642

-- Neovim起動時にcoc起動した場合、エクステンションが未導入の場合は個別にインストールする
vim.cmd([[
  let g:coc_global_extensions = [
    \'@yaegassy/coc-tailwindcss3',
    \'@yaegassy/coc-astro',
    \'coc-css',
    \'coc-go',
    \'coc-html',
    \'coc-json',
    \'coc-phpls',
    \'coc-rust-analyzer',
    \'coc-sumneko-lua',
    \'coc-tsserver',
    \'coc-vetur',
    \'coc-svelte',
    \'coc-yaml',
    \'coc-spell-checker'
  \]

  " tailwind.cssのconfigをtsでも認識するように変更
  au FileType html let b:coc_root_patterns = ['.git', '.env', 'tailwind.config.js', 'tailwind.config.cjs', 'tailwind.config.ts']
]])

local keyset = vim.api.nvim_set_keymap
local opts = {
  default = { silent = true, nowait = true, expr = true },
  silent_only =  { silent = true }
}

-- ヒントを表示
keyset('n', '<space>h', ':<C-u>call CocAction("doHover")<cr>', opts.silent_only)

-- CocListを表示
keyset('n', '<space>l', ':CocList<cr>', opts.silent_only)

-- 定義元ジャンプ
keyset('n', '<space>]', '<Plug>(coc-definition)', opts.silent_only)

-- cocで表示されるフローティングウィンドウのスクロールのキーマッピング
-- issues: https://github.com/neoclide/coc.nvim/issues/609
keyset('n', '<C-f>', 'coc#float#has_scroll() ? coc#float#scroll(1) : "<C-f>"', opts.default)
keyset('n', '<C-b>', 'coc#float#has_scroll() ? coc#float#scroll(0) : "<C-b>"', opts.default)
keyset('i', '<C-f>', 'coc#float#has_scroll() ? "<c-r>=coc#float#scroll(1)<cr>" : "<Right>"', opts.default)
keyset('i', '<C-b>', 'coc#float#has_scroll() ? "<c-r>=coc#float#scroll(0)<cr>" : "<Left>"', opts.default)
