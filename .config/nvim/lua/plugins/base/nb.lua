-- nb (Notebook CLI) integration for Neovim
-- Provides commands and keybindings to create and open notes using the nb command-line tool

local M = {}

-- ============================================================================
-- Type Definitions
-- ============================================================================

---@class NbNoteItem
---@field text string Display text for the note
---@field note_id string The note's ID in nb
---@field file string? Optional file path

-- ============================================================================
-- Configuration
-- ============================================================================

M.config = {
  open_mode = "buffer", -- How to open notes: 'buffer', 'tab', 'split', 'vsplit'
  default_notebook = nil, -- Default notebook (nil means use nb's default)
  auto_save = true, -- Auto save before running nb commands
  preview_float = true, -- Show preview in floating window (unused for now)
  use_snacks_picker = true, -- Enable Snacks.nvim picker integration
}

-- ============================================================================
-- Constants
-- ============================================================================

local NB_ENV = "NB_EDITOR=: NO_COLOR=1"
local NB_CMD = "nb"
local ANSI_ESCAPE_PATTERN = "\x1b%[[0-9;]*m"

local MESSAGES = {
  NB_NOT_FOUND = "nb CLI not found",
  UNKNOWN_ERROR = "Unknown error occurred while running nb add",
  NOTE_INFO_ERROR = "nb add succeeded but failed to retrieve note information",
  NOTE_ID_PARSE_ERROR = "Failed to parse note ID",
  NOTE_PATH_ERROR = "Failed to get note path",
  NOTE_OPEN_ERROR = "Failed to open note",
  NB_SHOW_ERROR = "nb show failed",
  BUFFER_OPENED = "Opened as buffer",
  TAB_OPENED = "Opened as tab",
  SPLIT_OPENED = "Opened in split window",
}

-- ============================================================================
-- Utility Functions
-- ============================================================================

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "nb" })
end

local function sanitize_output(text)
  if type(text) == "string" then
    return (text:gsub(ANSI_ESCAPE_PATTERN, ""))
  elseif type(text) == "table" then
    local sanitized = {}
    for _, line in ipairs(text) do
      table.insert(sanitized, (line:gsub(ANSI_ESCAPE_PATTERN, "")))
    end
    return sanitized
  end
  return text
end

-- ============================================================================
-- nb Command Execution
-- ============================================================================

local function execute_command(command)
  local full_command = NB_ENV .. " " .. command
  local output = vim.fn.systemlist(full_command)
  local exit_code = vim.v.shell_error
  return output, exit_code
end

local function run_nb_add(args)
  local command = NB_CMD .. " add --no-color"
  if args and args ~= "" then
    -- When arguments provided, use them as title
    -- nb will automatically create "# title" as the first line
    -- Also use timestamp format for filename to maintain consistency
    local compact_timestamp = os.date("%Y%m%d%H%M%S")
    local escaped_args = args:gsub('"', '\\"')
    command = command .. " --filename \"" .. compact_timestamp .. ".md\" --title \"" .. escaped_args .. "\""
  else
    -- When no arguments provided, create an empty note with timestamp title
    -- This prevents nb from trying to open an editor (which fails with NB_EDITOR=:)
    local compact_timestamp = os.date("%Y%m%d%H%M%S")
    local readable_timestamp = os.date("%Y-%m-%d %H:%M:%S")
    command = command .. " --filename \"" .. compact_timestamp .. ".md\" --title \"" .. readable_timestamp .. "\""
  end
  if M.config.default_notebook then
    command = M.config.default_notebook .. ":" .. command
  end
  return execute_command(command)
end

local function get_note_path(note_id)
  local command = string.format("%s show --no-color --path %q", NB_CMD, note_id)
  local full_command = NB_ENV .. " " .. command
  local path = vim.fn.system(full_command)
  local exit_code = vim.v.shell_error
  return vim.trim(path or ""), exit_code
end

-- ============================================================================
-- Note Processing Functions
-- ============================================================================

local function extract_note_info(output)
  for _, line in ipairs(output) do
    if line:match("^Added:") then
      return sanitize_output(line)
    end
  end
  return nil
end

local function parse_note_id(info_line)
  if not info_line then
    return nil
  end
  local note_id = info_line:match("%[(.-)%]")
  return note_id and note_id ~= "" and note_id or nil
end

local function open_note(path)
  local mode = M.config.open_mode

  -- Auto save if configured
  if M.config.auto_save and vim.bo.modified then
    vim.cmd("write")
  end

  -- Open based on mode
  local ok, err
  if mode == "tab" then
    ok, err = pcall(vim.cmd.tabedit, path)
  elseif mode == "split" then
    ok, err = pcall(vim.cmd.split, path)
  elseif mode == "vsplit" then
    ok, err = pcall(vim.cmd.vsplit, path)
  else -- buffer (default)
    ok, err = pcall(vim.cmd.edit, path)
  end

  if not ok then
    return false, err
  end

  -- Ensure buffer is listed
  local bufnr = vim.fn.bufnr("%")
  vim.bo[bufnr].buflisted = true
  return true
end

-- ============================================================================
-- Core nb Functions
-- ============================================================================

local function list_notes(args)
  local command = NB_CMD .. " list --no-color"
  if args and args ~= "" then
    command = command .. " " .. args
  end
  if M.config.default_notebook then
    command = M.config.default_notebook .. ":" .. command
  end

  local output, exit_code = execute_command(command)
  if exit_code ~= 0 then
    local error_output = sanitize_output(output)
    local message = table.concat(error_output, "\n")
    notify(message or "Error occurred while retrieving list", vim.log.levels.ERROR)
    return nil
  end

  return sanitize_output(output)
end

local function search_notes(args)
  local command = NB_CMD .. " search --no-color"
  if args and args ~= "" then
    command = command .. " " .. args
  else
    notify("Please specify a search query", vim.log.levels.ERROR)
    return nil
  end

  if M.config.default_notebook then
    command = M.config.default_notebook .. ":" .. command
  end

  local output, exit_code = execute_command(command)
  if exit_code ~= 0 then
    local error_output = sanitize_output(output)
    local message = table.concat(error_output, "\n")
    notify(message or "Error occurred during search", vim.log.levels.ERROR)
    return nil
  end

  return sanitize_output(output)
end

local function delete_note(note_id)
  if not note_id or note_id == "" then
    notify("Please specify a note ID", vim.log.levels.ERROR)
    return false
  end

  -- Confirm deletion
  local confirm = vim.fn.confirm(string.format("Delete note [%s]?", note_id), "&Yes\n&No", 2)
  if confirm ~= 1 then
    return false
  end

  local command = string.format("%s delete --force %q", NB_CMD, note_id)
  local _, exit_code = execute_command(command)

  if exit_code == 0 then
    notify(string.format("Deleted note [%s]", note_id), vim.log.levels.INFO)
    return true
  else
    notify(string.format("Failed to delete note [%s]", note_id), vim.log.levels.ERROR)
    return false
  end
end

local function edit_note(args)
  if not args or args == "" then
    notify("Please specify a note ID or number", vim.log.levels.ERROR)
    return
  end

  local note_id = vim.trim(args)
  if M.config.default_notebook then
    note_id = M.config.default_notebook .. ":" .. note_id
  end

  local note_path, exit_code = get_note_path(note_id)
  if exit_code ~= 0 then
    local error_msg = note_path ~= "" and note_path or "Specified note not found"
    notify(error_msg, vim.log.levels.ERROR)
    return
  end

  if note_path == "" then
    notify(MESSAGES.NOTE_PATH_ERROR, vim.log.levels.ERROR)
    return
  end

  local ok, err = open_note(note_path)
  if not ok then
    notify(MESSAGES.NOTE_OPEN_ERROR .. ": " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  notify("Opened note: " .. note_id, vim.log.levels.INFO)
end

-- Get note title and content for search (unused but kept for future use)
local function get_note_info(note_id, title_only)
  local path, _ = get_note_path(note_id)
  local title = ""
  local content = ""

  if path and path ~= "" then
    if title_only then
      local file = io.open(path, "r")
      if file then
        local first_line = file:read("*l")
        if first_line then
          local heading = first_line:match("^#%s+(.+)")
          title = heading or first_line:sub(1, 50)
        end
        file:close()
      end
    else
      local file = io.open(path, "r")
      if file then
        local all_content = file:read("*a")
        file:close()

        if all_content and all_content ~= "" then
          local lines = {}
          for line in all_content:gmatch("[^\n]*") do
            if line ~= "" then
              table.insert(lines, line)
            end
          end

          if #lines > 0 then
            local heading = lines[1]:match("^#%s+(.+)")
            title = heading or lines[1]:sub(1, 50)
          end
          content = all_content
        end
      end
    end
  end

  return title, content
end

-- ============================================================================
-- Snacks Picker Functions
-- ============================================================================

-- Parse nb ls output to extract note items
local function parse_note_list(notes)
  local items = {}
  for _, note in ipairs(notes) do
    local note_id, title = note:match("^%[(.-)%]%s+(.+)")
    if note_id then
      if title then
        title = title:gsub('^"', ""):gsub('"$', "")
      else
        title = "No title"
      end

      table.insert(items, {
        text = string.format("[%s] %s", note_id, title),
        note_id = note_id,
        file = nil,
      })
    end
  end
  return items
end

-- Parse nb search output to extract note items
local function parse_search_results(notes, search_query)
  local items = {}
  local i = 1
  while i <= #notes do
    local line = notes[i]
    local note_id = line:match("^%[(.-)%]")
    if note_id then
      -- Extract title
      local title_part = line:match("·%s+(.+)$")
      if not title_part then
        title_part = line:match("^%[.-%]%s+(.+)")
      end

      if title_part then
        title_part = title_part:gsub('^"', ""):gsub('"$', "")
      else
        title_part = "No title"
      end

      -- Check for match context
      local match_context = ""
      if search_query and search_query ~= "" and i + 2 <= #notes then
        local context_line = notes[i + 2]
        if context_line and not context_line:match("^%-+$") then
          local match_type = context_line:match("^(%w+ Match):")
          if match_type then
            match_context = " [" .. match_type .. "]"
          end
        end
      end

      table.insert(items, {
        text = string.format("[%s] %s%s", note_id, title_part, match_context),
        note_id = note_id,
        file = nil,
      })

      -- Skip to next entry
      i = i + 1
      while i <= #notes and (notes[i]:match("^%-+$") or notes[i]:match("^%s*$") or notes[i]:match("Match:")) do
        i = i + 1
      end
    else
      i = i + 1
    end
  end
  return items
end

-- Create a picker with common configuration
local function create_picker(title, items, Snacks, picker_type, search_query)
  return Snacks.picker({
    title = title,
    items = items,
    format = function(item)
      return {
        { item.text, "TelescopeResultsIdentifier" },
      }
    end,
    confirm = function(picker, item)
      if item and item.note_id then
        -- Close the picker first
        picker:close()
        -- Then open the note
        vim.schedule(function()
          edit_note(item.note_id)
        end)
      end
    end,
    -- Custom actions
    actions = {
      delete_note = function(picker)
        local item = picker:current()
        if item and item.note_id then
          if delete_note(item.note_id) then
            -- Close the picker and re-open with updated list
            picker:close()
            vim.schedule(function()
              -- Re-run the appropriate picker command
              if picker_type == "title" then
                vim.cmd("NbPickerTitle")
              elseif picker_type == "content" then
                if search_query and search_query ~= "" then
                  vim.cmd("NbPickerContent " .. search_query)
                else
                  vim.cmd("NbPickerContent")
                end
              end
            end)
          end
        end
      end,
    },
    -- Window configuration with keymaps
    win = {
      input = {
        keys = {
          ["<C-d>"] = { "delete_note", mode = { "n", "i" }, desc = "Delete note" },
        },
      },
      list = {
        keys = {
          ["D"] = { "delete_note", mode = "n", desc = "Delete note" },
          ["dd"] = { "delete_note", mode = "n", desc = "Delete note" },
        },
      },
    },
  })
end

-- Snacks picker for title search
local function snacks_nb_picker_title()
  local has_snacks, Snacks = pcall(require, "snacks")
  if not has_snacks then
    notify("Snacks.nvim is not installed", vim.log.levels.ERROR)
    return
  end

  local notes = list_notes("")
  if not notes then
    return
  end

  local items = parse_note_list(notes)
  local title = "📝 nb Notes | [Enter]: Open | [Ctrl-D/D/dd]: Delete"
  create_picker(title, items, Snacks, "title", nil)
end

-- Snacks picker for content search
local function snacks_nb_picker_content(search_query)
  local has_snacks, Snacks = pcall(require, "snacks")
  if not has_snacks then
    notify("Snacks.nvim is not installed", vim.log.levels.ERROR)
    return
  end

  -- Get notes based on search query
  local notes
  if search_query and search_query ~= "" then
    notes = search_notes(search_query)
  else
    notes = list_notes("")
  end
  if not notes then
    return
  end

  -- Parse and create picker
  local items = parse_search_results(notes, search_query)
  local base_title = search_query and search_query ~= "" and string.format("🔍 nb Search: '%s'", search_query)
    or "📝 nb Notes (All)"
  local title = base_title .. " | [Enter]: Open | [Ctrl-D/D/dd]: Delete"

  create_picker(title, items, Snacks, "content", search_query)
end

-- Legacy picker (for backward compatibility)
local function snacks_nb_picker()
  snacks_nb_picker_title()
end

-- ============================================================================
-- Main Command Functions
-- ============================================================================

-- Main function for adding notes
local function add_and_open_note(opts)
  -- Check if nb is available
  if vim.fn.executable(NB_CMD) ~= 1 then
    notify(MESSAGES.NB_NOT_FOUND, vim.log.levels.ERROR)
    return
  end

  -- Auto save if configured
  if M.config.auto_save and vim.bo.modified then
    vim.cmd("write")
  end

  -- Execute nb add command
  local args = vim.trim(opts and opts.args or "")

  -- Show info message when creating note
  if args == "" then
    notify("Creating new note (with timestamp)...", vim.log.levels.INFO)
  else
    notify("Creating new note: " .. args, vim.log.levels.INFO)
  end

  local output, exit_code = run_nb_add(args)

  -- Handle errors
  if exit_code ~= 0 then
    local error_output = sanitize_output(output)
    local message = table.concat(error_output, "\n")
    notify(message ~= "" and message or MESSAGES.UNKNOWN_ERROR, vim.log.levels.ERROR)
    return
  end

  -- Extract note information
  local info_line = extract_note_info(output)
  if not info_line then
    notify(MESSAGES.NOTE_INFO_ERROR, vim.log.levels.ERROR)
    return
  end

  -- Parse note ID
  local note_id = parse_note_id(info_line)
  if not note_id then
    notify(MESSAGES.NOTE_ID_PARSE_ERROR .. ": " .. info_line, vim.log.levels.ERROR)
    return
  end

  -- Get note path
  local note_path, path_exit_code = get_note_path(note_id)
  if path_exit_code ~= 0 then
    local error_msg = note_path ~= "" and note_path or MESSAGES.NB_SHOW_ERROR
    notify(error_msg, vim.log.levels.ERROR)
    return
  end

  if note_path == "" then
    notify(MESSAGES.NOTE_PATH_ERROR, vim.log.levels.ERROR)
    return
  end

  -- Open the note
  local ok, err = open_note(note_path)
  if not ok then
    notify(MESSAGES.NOTE_OPEN_ERROR .. ": " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  -- Show success message
  local display_message = (info_line:gsub("^Added:%s*", ""))
  local open_msg = MESSAGES[string.upper(M.config.open_mode) .. "_OPENED"] or MESSAGES.BUFFER_OPENED
  notify("nb add: " .. display_message .. " (" .. open_msg .. ")", vim.log.levels.INFO)
end

-- ============================================================================
-- Setup Function
-- ============================================================================

function M.setup(opts)
  -- Merge user options with defaults
  if opts then
    M.config = vim.tbl_deep_extend("force", M.config, opts)
  end

  -- Remove existing commands if they exist
  local commands = { "NbAdd", "NbSearch", "NbEdit", "NbPicker", "NbPickerTitle", "NbPickerContent" }
  for _, cmd in ipairs(commands) do
    pcall(vim.api.nvim_del_user_command, cmd)
  end

  -- Create NbAdd command
  vim.api.nvim_create_user_command("NbAdd", add_and_open_note, {
    desc = "Run nb add and open the created note",
    nargs = "*",
    complete = "shellcmd",
  })

  -- Create NbSearch command
  vim.api.nvim_create_user_command("NbSearch", function(cmd_opts)
    local results = search_notes(cmd_opts and cmd_opts.args or "")
    if not results then
      return
    end

    -- Create scratch buffer
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, results)
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].modifiable = false

    -- Open in split
    vim.cmd("split")
    vim.api.nvim_win_set_buf(0, buf)

    -- Set up keymaps
    vim.keymap.set("n", "<CR>", function()
      local line = vim.api.nvim_get_current_line()
      local note_id = line:match("^%[(.-)%]")
      if note_id then
        vim.cmd("close")
        edit_note(note_id)
      end
    end, { buffer = buf, noremap = true, silent = true, desc = "Open note" })

    vim.keymap.set("n", "q", ":close<CR>", {
      buffer = buf,
      noremap = true,
      silent = true,
      desc = "Close search results",
    })
  end, {
    desc = "Search notes with nb",
    nargs = "+",
    complete = "shellcmd",
  })

  -- Create NbEdit command
  vim.api.nvim_create_user_command("NbEdit", function(cmd_opts)
    if cmd_opts and cmd_opts.args then
      edit_note(cmd_opts.args)
    end
  end, {
    desc = "Edit existing nb note",
    nargs = "+",
    complete = function(arglead)
      local notes = list_notes("")
      if not notes then
        return {}
      end

      local completions = {}
      for _, note in ipairs(notes) do
        local id = note:match("^%[(.-)%]")
        if id and id:match("^" .. vim.pesc(arglead)) then
          table.insert(completions, id)
        end
      end
      return completions
    end,
  })

  -- Create Snacks picker commands if available
  if M.config.use_snacks_picker then
    vim.api.nvim_create_user_command("NbPicker", snacks_nb_picker, {
      desc = "Search nb notes with Snacks picker (title)",
      nargs = 0,
    })

    vim.api.nvim_create_user_command("NbPickerTitle", snacks_nb_picker_title, {
      desc = "Search by title with Snacks picker",
      nargs = 0,
    })

    vim.api.nvim_create_user_command("NbPickerContent", function(cmd_opts)
      local query = cmd_opts and cmd_opts.args or ""
      snacks_nb_picker_content(query)
    end, {
      desc = "Search by content with Snacks picker",
      nargs = "*",
    })
  end
end

-- ============================================================================
-- Export Module
-- ============================================================================

M.name = "nb-integration"

-- ============================================================================
-- LazyNvim Plugin Configuration
-- ============================================================================

local plugin = {
  name = "nb-integration",
  dir = vim.fn.stdpath("config"),
  lazy = false,
  config = function()
    M.setup()
  end,
  dependencies = {
    "folke/snacks.nvim",
  },
  keys = {
    {
      "<leader>na",
      function()
        vim.cmd("NbAdd")
      end,
      desc = "nb add (create new note)",
      silent = true,
    },
    {
      "<leader>ns",
      function()
        vim.ui.input({ prompt = "Search notes: " }, function(input)
          if input then
            vim.cmd("NbSearch " .. input)
          end
        end)
      end,
      desc = "nb search notes",
      silent = true,
    },
    {
      "<leader>ne",
      function()
        vim.ui.input({ prompt = "Edit note ID: " }, function(input)
          if input then
            vim.cmd("NbEdit " .. input)
          end
        end)
      end,
      desc = "nb edit note",
      silent = true,
    },
    {
      "<leader>np",
      function()
        if M.config.use_snacks_picker then
          vim.cmd("NbPicker")
        else
          vim.notify("Snacks picker integration is disabled", vim.log.levels.WARN, { title = "nb" })
        end
      end,
      desc = "nb picker (title search)",
      silent = true,
    },
    {
      "<leader>nt",
      function()
        if M.config.use_snacks_picker then
          vim.cmd("NbPickerTitle")
        else
          vim.notify("Snacks picker integration is disabled", vim.log.levels.WARN, { title = "nb" })
        end
      end,
      desc = "nb picker title search",
      silent = true,
    },
    {
      "<leader>nc",
      function()
        vim.ui.input({ prompt = "Content search query: " }, function(input)
          if M.config.use_snacks_picker then
            if input then
              vim.cmd("NbPickerContent " .. input)
            else
              vim.cmd("NbPickerContent")
            end
          else
            vim.notify("Snacks picker integration is disabled", vim.log.levels.WARN, { title = "nb" })
          end
        end)
      end,
      desc = "nb picker content search",
      silent = true,
    },
  },
}

-- Return the plugin configuration
return plugin
