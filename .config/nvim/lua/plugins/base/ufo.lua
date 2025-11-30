-- Custom provider for :::details folding (Zenn markdown syntax)
local function detailsFoldProvider(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local folds = {}
  local stack = {}

  for i, line in ipairs(lines) do
    local lineNum = i - 1 -- 0-indexed
    if line:match("^:::details") then
      table.insert(stack, lineNum)
    elseif line:match("^:::$") and #stack > 0 then
      local startLine = table.remove(stack)
      table.insert(folds, { startLine = startLine, endLine = lineNum, kind = "region" })
    end
  end

  return folds
end

-- Custom fold text handler to show :::details title
local function foldTextHandler(virtText, lnum, endLnum, width, truncate)
  local newVirtText = {}
  local suffix = (" 󰁂 %d lines"):format(endLnum - lnum)
  local sufWidth = vim.fn.strdisplaywidth(suffix)
  local targetWidth = width - sufWidth
  local curWidth = 0

  for _, chunk in ipairs(virtText) do
    local chunkText = chunk[1]
    local chunkWidth = vim.fn.strdisplaywidth(chunkText)
    if targetWidth > curWidth + chunkWidth then
      table.insert(newVirtText, chunk)
    else
      chunkText = truncate(chunkText, targetWidth - curWidth)
      local hlGroup = chunk[2]
      table.insert(newVirtText, { chunkText, hlGroup })
      chunkWidth = vim.fn.strdisplaywidth(chunkText)
      if curWidth + chunkWidth < targetWidth then
        suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
      end
      break
    end
    curWidth = curWidth + chunkWidth
  end

  table.insert(newVirtText, { suffix, "Comment" })
  return newVirtText
end

return {
  "kevinhwang91/nvim-ufo",
  dependencies = {
    "kevinhwang91/promise-async",
  },
  event = "VeryLazy",
  opts = {
    fold_virt_text_handler = foldTextHandler,
    provider_selector = function(bufnr, filetype, buftype)
      if filetype == "markdown" then
        return function(bufnr)
          local detailsFolds = detailsFoldProvider(bufnr)
          if #detailsFolds > 0 then
            return detailsFolds
          end
          return nil -- Fallback to default providers
        end
      end
      return { "treesitter", "indent" }
    end,
  },
  init = function()
    vim.o.foldcolumn = "1" -- '0' is not bad
    vim.o.foldlevel = 99 -- Using ufo provider need a large value
    vim.o.foldlevelstart = 99
    vim.o.foldenable = true
  end,
  keys = {
    {
      "zR",
      function()
        require("ufo").openAllFolds()
      end,
      desc = "Open all folds",
    },
    {
      "zM",
      function()
        require("ufo").closeAllFolds()
      end,
      desc = "Close all folds",
    },
    {
      "zr",
      function()
        require("ufo").openFoldsExceptKinds()
      end,
      desc = "Fold less",
    },
    {
      "zm",
      function()
        require("ufo").closeFoldsWith()
      end,
      desc = "Fold more",
    },
    {
      "K",
      function()
        local winid = require("ufo").peekFoldedLinesUnderCursor()
        if not winid then
          vim.lsp.buf.hover()
        end
      end,
      desc = "Peek fold or hover",
    },
  },
}
