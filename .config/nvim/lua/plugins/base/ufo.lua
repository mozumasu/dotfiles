-- Custom markdown fold provider for :::details and headings
---@param bufnr number
---@return UfoFoldingRange[]
local function markdownFoldProvider(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local folds = {}
  local detailsStack = {}
  local headingStack = {} -- {lineNum, level}

  local function getHeadingLevel(line)
    local hashes = line:match("^(#+)%s")
    return hashes and #hashes or 0
  end

  local function skipTrailingEmptyLines(endLine)
    while endLine > 0 and lines[endLine + 1] and lines[endLine + 1]:match("^%s*$") do
      endLine = endLine - 1
    end
    return endLine
  end

  local function closeHeadingsAtOrAbove(level, endLine)
    while #headingStack > 0 and headingStack[#headingStack].level >= level do
      local h = table.remove(headingStack)
      local adjustedEnd = skipTrailingEmptyLines(endLine - 1)
      if adjustedEnd > h.lineNum then
        table.insert(folds, { startLine = h.lineNum, endLine = adjustedEnd })
      end
    end
  end

  for i, line in ipairs(lines) do
    local lineNum = i - 1 -- 0-indexed

    -- Handle :::details
    if line:match("^:::details") then
      table.insert(detailsStack, lineNum)
    elseif line:match("^:::$") and #detailsStack > 0 then
      local startLine = table.remove(detailsStack)
      table.insert(folds, { startLine = startLine, endLine = lineNum })
    end

    -- Handle headings
    local level = getHeadingLevel(line)
    if level > 0 then
      closeHeadingsAtOrAbove(level, lineNum)
      table.insert(headingStack, { lineNum = lineNum, level = level })
    end
  end

  -- Close remaining headings at end of file
  local lastLine = skipTrailingEmptyLines(#lines - 1)
  for j = #headingStack, 1, -1 do
    local h = headingStack[j]
    if lastLine > h.lineNum then
      table.insert(folds, { startLine = h.lineNum, endLine = lastLine })
    end
  end

  return folds
end

-- Custom fold text handler to show fold info
local function foldTextHandler(virtText, lnum, endLnum, width, truncate)
  local newVirtText = {}
  local suffix = (" 󰁂 %d "):format(endLnum - lnum)
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

  table.insert(newVirtText, { suffix, "MoreMsg" })
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
        return markdownFoldProvider
      end
      return { "treesitter", "indent" }
    end,
  },
  init = function()
    vim.o.foldcolumn = "1"
    vim.o.foldlevel = 99
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
