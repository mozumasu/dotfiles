local wezterm = require("wezterm")
local module = {}

-- Language detection function
local function detect_language(text)
  -- Check if text contains only ASCII characters
  -- If non-ASCII characters are found, assume it's Japanese
  for i = 1, #text do
    if text:byte(i) > 127 then
      return "Japanese", "English"
    end
  end
  return "English", "Japanese"
end

-- Display translation result in a new pane
local function translate_text_in_pane(text, _, pane)
  if not text or text == "" then
    return
  end

  -- Remove leading and trailing whitespace
  text = text:gsub("^%s+", ""):gsub("%s+$", "")

  local from_lang, to_lang = detect_language(text)

  -- Escape single quotes for shell command
  local escaped_text = text:gsub("'", "'\\''")

  -- Display translation result in a split pane
  pane:split({
    direction = "Bottom",
    size = 0.3,
    args = {
      "sh",
      "-c",
      string.format(
        [[
        # Run translation
        result=$(/Users/mozumasu/.local/bin/plamo-translate \
          --no-stream --from '%s' --to '%s' --input '%s' 2>&1)
        exit_code=$?

        if [ $exit_code -eq 0 ] && [ -n "$result" ]; then
          {
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Translation Result (%s → %s)"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "$result"
          } | /opt/homebrew/bin/nvim -R -c 'set filetype=markdown' -c 'nnoremap q :q<CR>' -c 'normal! gg' -
        else
          {
            echo "✗ Translation Error"
            echo ""
            echo "$result"
          } | /opt/homebrew/bin/nvim -R -c 'set filetype=markdown' -c 'nnoremap q :q<CR>' -c 'normal! gg' -
        fi
      ]],
        from_lang,
        to_lang,
        escaped_text,
        from_lang,
        to_lang
      ),
    },
  })
end

-- Export the translate function for use in keymaps
module.translate_text_in_pane = translate_text_in_pane

return module
