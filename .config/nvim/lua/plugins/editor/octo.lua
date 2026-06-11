return {
  "pwntester/octo.nvim",
  keys = {
    {
      "<leader>gP",
      "<cmd>OctoSearchProject<CR>",
      desc = "Search Project Issues (with completion)",
    },
  },
  config = function(_, opts)
    -- octo://バッファはGitHub APIが実態のため、スワップファイル不要
    -- BufReadCmd: octo.nvimが内部でバッファ読み込みを行う際に発火
    vim.api.nvim_create_autocmd("BufReadCmd", {
      pattern = "octo://*",
      callback = function()
        vim.opt_local.swapfile = false
      end,
    })
    -- render-markdown.nvim が octo バッファを装飾できるよう
    -- octo filetype に markdown treesitter parser を割り当てる
    vim.treesitter.language.register("markdown", "octo")
    require("octo").setup(opts)

    -- Neovim 0.12.x の segfault 回避: octo の clear_history はグローバル
    -- undolevels=-1 の状態で "normal a <BS>" を実行する。その間に発火する
    -- autocmd (InsertEnter 等) で他プラグインが新規バッファへ初回書き込みを
    -- 行うと、そのバッファは「undo ヘッダなし・未同期」となり、後で削除された
    -- ときに u_savecommon が NULL 参照して Neovim ごと落ちる
    -- (skkeleton_indicator のフロートで発生。--clean で最小再現を確認済み)。
    -- undolevels をバッファローカルに差し替え、影響を octo バッファに閉じる。
    local octo_utils = require("octo.utils")
    function octo_utils.clear_history()
      local old_undolevels = vim.bo.undolevels
      vim.bo.undolevels = -1
      vim.cmd [[exe "normal a \<BS>"]]
      vim.bo.undolevels = old_undolevels
    end

    -- octo の load_buffer は gh の非同期応答後に nvim_buf_call(bufnr, ...) を
    -- バッファ有効性チェックなしで呼ぶため、応答前にプレビューバッファが
    -- 掃除されると "Invalid buffer id" エラーになる (octo 上流の race)。
    -- バッファ消滅由来のエラーだけ握りつぶす。
    local octo = require("octo")
    local orig_load = octo.load
    ---@diagnostic disable-next-line: duplicate-set-field
    octo.load = function(repo, kind, id, hostname, cb)
      return orig_load(repo, kind, id, hostname, function(obj)
        local ok, err = pcall(cb, obj)
        if not ok and not tostring(err):match("Invalid buffer id") then
          error(err)
        end
      end)
    end

    -- render-markdown を octo ロード時(=安全なタイミング)に先読みしておく。
    -- FileType=octo での遅延ロードを避けることで、ピッカーのプレビューバッファ
    -- 生成中に同期ロードがストールして起きる race (Invalid buffer id) を防ぐ。
    pcall(function()
      require("lazy").load { plugins = { "render-markdown.nvim" } }
    end)
  end,
}
