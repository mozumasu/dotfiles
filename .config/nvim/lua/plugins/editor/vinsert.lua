return {
  "yuki-yano/vinsert.vim",
  lazy = false,
  cmd = { "VinsertToggle" },
  keys = {
    { "<C-.>", mode = { "i" } },
  },
  dependencies = { "vim-denops/denops.vim" },
  config = function()
    vim.g.vinsert_openai_api_key = os.getenv("OPENAI_API_KEY") or ""
    -- ffmpeg -f avfoundation -list_devices true -i ""
    vim.g.vinsert_ffmpeg_args = { "-f", "avfoundation", "-i", ":0" }

    vim.g.vinsert_stt_streaming_mode = "progressive"
    vim.g.vinsert_indicator = "virt" -- virt | statusline | cmdline | none
    vim.g.vinsert_always_yank = true

    vim.g.vinsert_debug = true
    vim.g.vinsert_text_stream = false

    vim.keymap.set("i", "<C-.>", function()
      vim.cmd("VinsertToggle insert")
    end, { silent = true })
    vim.keymap.set("i", "<C-w>", function()
      local status = vim.fn["vinsert#status"]()
      if status.active then
        vim.cmd("VinsertCancel")
        return ""
      end
      return "<C-w>"
    end, { expr = true, silent = true })

    vim.api.nvim_create_autocmd("User", {
      pattern = "VinsertComplete",
      callback = function()
        local result = vim.g.vinsert_last_completion or {}
        local body = table.concat({
          string.format("Mode: %s", result.mode or "unknown"),
          string.format("Success: %s", tostring(result.success)),
          "",
          result.final or "(no text)",
        }, "\n")
        vim.notify(body, vim.log.levels.INFO, { title = "vinsert" })
      end,
    })
  end,
}
