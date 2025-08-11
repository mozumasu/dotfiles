local wezterm = require("wezterm")

local module = {}

-- EditPrompt-like feature: Edit in nvim and send as Claude Code prompt
function module.edit_prompt()
  return {
    key = "A",
    mods = "CTRL",
    action = wezterm.action_callback(function(window, pane)
      -- Create temporary file
      local temp_base = os.tmpname()
      os.remove(temp_base) -- Remove the file created by os.tmpname()
      local temp_file = temp_base .. ".md"

      -- Get current input text
      local current_text = ""

      -- Get pane dimensions
      local dims = pane:get_dimensions()
      local viewport_rows = dims.viewport_rows

      -- Get text from scrollback (current viewport)
      local lines = ""

      -- Method 1: Get from current viewport
      if viewport_rows and viewport_rows > 0 then
        lines = pane:get_lines_as_text(viewport_rows)
      end

      -- Method 2: Retry with fixed value if empty
      if not lines or lines == "" then
        lines = pane:get_lines_as_text(50)
      end

      -- Split text into lines
      local all_lines = {}
      for line in lines:gmatch("[^\r\n]*") do
        table.insert(all_lines, line)
      end

      -- Find Claude Code prompt box (only the last one)
      -- Search in reverse order to find the latest prompt box
      local prompt_lines = {}
      local found_box = false

      -- Debug: Uncomment to enable logging when needed
      local debug_file = nil -- io.open("/tmp/wezterm_debug.log", "w")

      -- Find the last prompt box (reverse order)
      local box_end = 0
      local box_start = 0

      for i = #all_lines, 1, -1 do
        local line = all_lines[i]
        if line:match("^╰─") and box_end == 0 then
          box_end = i
          -- if debug_file then debug_file:write(string.format("Found box end at line %d\n", i)) end
        elseif line:match("^╭─") and box_end > 0 then
          box_start = i
          -- if debug_file then debug_file:write(string.format("Found box start at line %d\n", i)) end
          break
        end
      end

      -- Extract text from found box
      if box_start > 0 and box_end > box_start then
        for i = box_start + 1, box_end - 1 do
          local line = all_lines[i]
          -- Extract text from prompt line (simplest approach)
          local prompt_text = nil

          -- Remove decoration characters from line (using regex)
          local clean_line = line

          -- Remove leading decoration characters
          clean_line = clean_line:gsub("^│", "")
          clean_line = clean_line:gsub("^|", "")
          clean_line = clean_line:gsub("^┃", "")

          -- Replace non-breaking space (UTF-8: 0xC2 0xA0) with normal space
          clean_line = clean_line:gsub(string.char(194, 160), " ")

          -- Remove leading whitespace (after removing decorations)
          clean_line = clean_line:gsub("^%s+", "")
          clean_line = clean_line:gsub("^[ \t]+", "")

          -- Remove trailing decoration characters and excessive whitespace
          clean_line = clean_line:gsub("%s*│$", "")
          clean_line = clean_line:gsub("%s*|$", "")
          clean_line = clean_line:gsub("%s*┃$", "")
          clean_line = clean_line:gsub("%s+$", "")

          if clean_line:find(">") then
            -- Get text after > using regex (multibyte-safe)
            prompt_text = clean_line:match(">%s*(.*)$")
            if prompt_text then
              -- Trim leading and trailing whitespace
              prompt_text = prompt_text:match("^%s*(.-)%s*$") or prompt_text
            end
          else
            -- Trim whitespace for lines without >
            prompt_text = clean_line:match("^%s*(.-)%s*$") or clean_line
          end

          -- Final check
          if prompt_text and prompt_text ~= "" then
            -- if debug_file then
            --   debug_file:write(string.format("Adding text: [%s]\n", prompt_text))
            -- end
            table.insert(prompt_lines, prompt_text)
          end
        end
      end

      -- Combine multi-line prompt
      if #prompt_lines > 0 then
        current_text = table.concat(prompt_lines, "\n")
      else
        for i = #all_lines, 1, -1 do
          local line = all_lines[i]
          if line and line ~= "" then
            -- Simply remove decoration characters and extract text
            local clean_line = line
            clean_line = clean_line:gsub("^[│┃|]%s*", "")
            clean_line = clean_line:gsub("%s*[│┃|]%s*$", "")
            clean_line = clean_line:gsub("^>%s*", "")
            clean_line = clean_line:gsub("^%s+", "")
            clean_line = clean_line:gsub("%s+$", "")

            if
              clean_line ~= ""
              and not clean_line:match("^Press ")
              and not clean_line:match("^✓")
              and not clean_line:match("^×")
              and not clean_line:match("^🤖")
              and not clean_line:match("^⏺")
              and not clean_line:match("^✻")
            then
              current_text = clean_line
              -- if debug_file then
              --   debug_file:write(string.format("Fallback found text at line %d: [%s]\n", i, current_text))
              -- end
              break
            end
          end
        end
      end

      -- if debug_file then
      --   debug_file:write(string.format("\n=== Final current_text ===\n[%s]\n", current_text))
      --   debug_file:close()
      -- end

      -- Prepare content to write to file (UTF-8 encoding)
      local file = io.open(temp_file, "wb") -- Open in binary mode
      if file then
        -- Write existing text if available (no header)
        if current_text and current_text ~= "" then
          -- Remove unnecessary leading whitespace from each line
          local lines = {}
          for line in current_text:gmatch("[^\n]*") do
            -- Trim whitespace from each line (preserve empty lines)
            if line ~= "" then
              line = line:gsub("^%s+", ""):gsub("%s+$", "")
            end
            table.insert(lines, line)
          end
          -- Write if first line is not empty
          local clean_text = table.concat(lines, "\n")
          clean_text = clean_text:gsub("^%s+", "") -- Remove leading whitespace again
          file:write(clean_text)
        end
        -- Empty file if no text

        file:close()
      end

      -- Open nvim in new pane
      pane:split({
        direction = "Bottom",
        size = 0.4,
        args = {
          "sh",
          "-c",
          string.format(
            [[
            /opt/homebrew/bin/nvim '%s' && \
            if [ -s '%s' ]; then
              content=$(cat '%s')
              if [ -n "$content" ]; then
                echo "$content" | pbcopy
                echo "✓ Prompt copied to clipboard. Press Cmd+V in Claude Code to paste."
              else
                echo "× No content to send."
              fi
            else
              echo "× File is empty."
            fi
            rm -f '%s'
            read -p "Press Enter to close this pane..."
            ]],
            temp_file,
            temp_file,
            temp_file,
            temp_file
          ),
        },
      })
    end),
  }
end

return module
