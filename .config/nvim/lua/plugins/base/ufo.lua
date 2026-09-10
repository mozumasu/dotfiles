local function isSeparator(line)
  return line:match("^%-%-%-%s*$") ~= nil
end

local function isFrontmatterKey(line)
  return line ~= nil and line:match("^[%w_%-]+%s*:") ~= nil
end

-- 区切り直後の frontmatter に現れたら Slidev とみなすキー
local SLIDEV_KEYS = {
  theme = true,
  transition = true,
  mdc = true,
  titleTemplate = true,
  drawings = true,
  layout = true,
  class = true,
  clicks = true,
  level = true,
  hide = true,
  src = true,
  routeAlias = true,
  zoom = true,
  background = true,
  backgroundSize = true,
  dragPos = true,
  preload = true,
}

-- 各スライドの開始行と frontmatter の行範囲を返す (すべて 0-indexed)。
-- スライド区切り直後の frontmatter を閉じる `---` は区切りではない
local function collectSlides(lines)
  local slides = {}
  local i = 1

  -- 先頭 frontmatter (headmatter) は最初のスライドのもの
  if lines[1] and isSeparator(lines[1]) then
    local j = 2
    while j <= #lines and not isSeparator(lines[j]) do
      j = j + 1
    end
    table.insert(slides, { start = 0, fmFrom = 1, fmTo = j - 2 })
    i = j + 1
  end

  local inCodeBlock = false
  while i <= #lines do
    local line = lines[i]
    if line:match("^```") or line:match("^~~~") then
      inCodeBlock = not inCodeBlock
    elseif not inCodeBlock and isSeparator(line) then
      local slide = { start = i - 1 }
      if isFrontmatterKey(lines[i + 1]) then
        local j = i + 1
        while j <= #lines and not isSeparator(lines[j]) do
          j = j + 1
        end
        if j <= #lines then
          slide.fmFrom, slide.fmTo = i, j - 2
          i = j
        end
      end
      table.insert(slides, slide)
    end
    i = i + 1
  end

  return slides
end

-- Zenn 記事の水平線を巻き込まないよう、Slidev のデッキだけに限定する。
-- pages/*.md に分割されたデッキは headmatter を持たないので frontmatter のキーで判定する
local function isSlidevBuffer(bufnr, lines, slides)
  if vim.api.nvim_buf_get_name(bufnr):match("slides%.md$") then
    return true
  end
  if #slides < 2 then
    return false
  end
  for _, slide in ipairs(slides) do
    for k = (slide.fmFrom or 0) + 1, (slide.fmTo or -1) + 1 do
      local key = lines[k]:match("^([%w_%-]+)%s*:")
      if key and SLIDEV_KEYS[key] then
        return true
      end
    end
  end
  return false
end

---@param startIdx number 1-indexed inclusive
---@param endIdx number 1-indexed inclusive
local function slideTitle(lines, startIdx, endIdx)
  local frontmatterTitle
  local i = startIdx

  if lines[i] and isSeparator(lines[i]) then
    i = i + 1
    if isFrontmatterKey(lines[i]) then
      while i <= endIdx and not isSeparator(lines[i]) do
        local t = lines[i]:match("^title%s*:%s*(.+)$")
        if t then
          frontmatterTitle = t:gsub("^[\"']", ""):gsub("[\"']$", "")
        end
        i = i + 1
      end
      i = i + 1
    end
  end

  if frontmatterTitle then
    return frontmatterTitle
  end
  for k = i, endIdx do
    local heading = lines[k]:match("^#+%s+(.+)$")
    if heading then
      return heading
    end
  end
  for k = i, endIdx do
    if not lines[k]:match("^%s*$") then
      return (lines[k]:gsub("^%s+", ""))
    end
  end
  return nil
end

-- Custom markdown fold provider for Zenn blocks (:::details, :::message), headings and Slidev slides
---@param bufnr number
---@return UfoFoldingRange[]
local function markdownFoldProvider(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local folds = {}
  local zennBlockStack = {}
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

  local slides = collectSlides(lines)
  local isSlidev = isSlidevBuffer(bufnr, lines, slides)
  if not isSlidev then
    slides = {}
  end
  local isSlideStart = {}
  for _, slide in ipairs(slides) do
    isSlideStart[slide.start] = true
  end

  local inCodeBlock = false
  local codeBlockStart = nil

  for i, line in ipairs(lines) do
    local lineNum = i - 1 -- 0-indexed

    if isSlideStart[lineNum] then
      closeHeadingsAtOrAbove(1, lineNum)
    end

    -- Track code blocks (``` or ~~~) and create folds for them
    if line:match("^```") or line:match("^~~~") then
      if not inCodeBlock then
        -- Starting a code block
        inCodeBlock = true
        codeBlockStart = lineNum
      else
        -- Ending a code block
        inCodeBlock = false
        if codeBlockStart and lineNum > codeBlockStart then
          table.insert(folds, { startLine = codeBlockStart, endLine = lineNum })
        end
        codeBlockStart = nil
      end
    end

    -- Handle Zenn blocks: :::details, :::message (outside code blocks)
    if not inCodeBlock then
      if line:match("^:::details") or line:match("^:::message") then
        table.insert(zennBlockStack, lineNum)
      elseif line:match("^:::$") and #zennBlockStack > 0 then
        local startLine = table.remove(zennBlockStack)
        table.insert(folds, { startLine = startLine, endLine = lineNum })
      end

      -- Handle headings (outside code blocks)
      local level = getHeadingLevel(line)
      if level > 0 then
        closeHeadingsAtOrAbove(level, lineNum)
        table.insert(headingStack, { lineNum = lineNum, level = level })
      end
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

  -- 区切り行自体は畳まない。render-markdown が水平線で上書きしてしまい
  -- 折り畳み時のタイトルが見えなくなる
  for idx, slide in ipairs(slides) do
    local nextSlide = slides[idx + 1]
    local startLine = slide.start + 1
    local endLine = nextSlide and nextSlide.start - 1 or #lines - 1
    if endLine > startLine then
      table.insert(folds, { startLine = startLine, endLine = endLine })
    end
  end

  return folds
end

-- Custom fold text handler to show fold info
local function foldTextHandler(virtText, lnum, endLnum, width, truncate, ctx)
  local newVirtText = {}
  local suffix = (" 󰁂 %d "):format(endLnum - lnum)
  local sufWidth = vim.fn.strdisplaywidth(suffix)
  local targetWidth = width - sufWidth
  local curWidth = 0

  -- スライド区切りの `---` だけでは中身が分からないのでタイトルに差し替える
  local bufnr = ctx and ctx.bufnr or vim.api.nvim_get_current_buf()
  if lnum >= 2 then
    -- 区切り行から読むと slideTitle が frontmatter をそのまま解釈できる
    local slideLines = vim.api.nvim_buf_get_lines(bufnr, lnum - 2, endLnum, false)
    if slideLines[1] and isSeparator(slideLines[1]) then
      local title = slideTitle(slideLines, 1, #slideLines)
      if title then
        virtText = { { "󰐩 " .. title, "Title" } }
      end
    end
  end

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
