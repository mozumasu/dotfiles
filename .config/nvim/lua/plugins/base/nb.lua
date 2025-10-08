-- nb (Notebook CLI) integration for Neovim
-- Provides commands and keybindings to create and open notes using the nb command-line tool

local M = {}

-- Type definitions
---@class NbNoteItem
---@field text string
---@field note_id string
---@field file string?

-- Default configuration
M.config = {
  -- How to open notes
  open_mode = "buffer", -- "buffer", "tab", "split", "vsplit"
  -- Default notebook (nil means use nb's default)
  default_notebook = nil,
  -- Auto save before running nb commands
  auto_save = true,
  -- Show preview in floating window
  preview_float = true,
  -- Snacks picker integration
  use_snacks_picker = true,
}

-- Constants
local NB_ENV = "NB_EDITOR=: NO_COLOR=1"
local NB_CMD = "nb"
local ANSI_ESCAPE_PATTERN = "\x1b%[[0-9;]*m"

-- Messages
local MESSAGES = {
  NB_NOT_FOUND = "nb CLI が見つかりません",
  UNKNOWN_ERROR = "nb add 実行中に不明なエラーが発生しました",
  NOTE_INFO_ERROR = "nb add は成功しましたがノート情報を取得できませんでした",
  NOTE_ID_PARSE_ERROR = "ノート ID を解析できません",
  NOTE_PATH_ERROR = "ノートのパスを取得できませんでした",
  NOTE_OPEN_ERROR = "ノートを開けませんでした",
  NB_SHOW_ERROR = "nb show に失敗しました",
  BUFFER_OPENED = "バッファとして開きました",
  TAB_OPENED = "タブとして開きました",
  SPLIT_OPENED = "分割ウィンドウで開きました",
}

-- Utility functions
local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "nb" })
end

local function sanitize_output(text)
  if type(text) == "string" then
    return text:gsub(ANSI_ESCAPE_PATTERN, "")
  elseif type(text) == "table" then
    local sanitized = {}
    for _, line in ipairs(text) do
      table.insert(sanitized, line:gsub(ANSI_ESCAPE_PATTERN, ""))
    end
    return sanitized
  end
  return text
end

-- nb command execution
local function execute_command(command)
  local full_command = NB_ENV .. " " .. command
  local output = vim.fn.systemlist(full_command)
  local exit_code = vim.v.shell_error
  return output, exit_code
end

local function run_nb_add(args)
  local command = NB_CMD .. " add --no-color"
  if args and args ~= "" then
    command = command .. " " .. args
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

-- Note processing
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
  local ok, err

  -- Auto save if configured
  if M.config.auto_save and vim.bo.modified then
    vim.cmd("write")
  end

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

  -- Ensure buffer is listed in the buffer list
  local bufnr = vim.fn.bufnr("%")
  vim.bo[bufnr].buflisted = true

  return true
end

-- List notes
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
    notify(message or "リスト取得中にエラーが発生しました", vim.log.levels.ERROR)
    return nil
  end

  return sanitize_output(output)
end

-- Search notes
local function search_notes(args)
  local command = NB_CMD .. " search --no-color"
  if args and args ~= "" then
    command = command .. " " .. args
  else
    notify("検索クエリを指定してください", vim.log.levels.ERROR)
    return nil
  end

  if M.config.default_notebook then
    command = M.config.default_notebook .. ":" .. command
  end

  local output, exit_code = execute_command(command)

  if exit_code ~= 0 then
    local error_output = sanitize_output(output)
    local message = table.concat(error_output, "\n")
    notify(message or "検索中にエラーが発生しました", vim.log.levels.ERROR)
    return nil
  end

  return sanitize_output(output)
end

-- Edit existing note
local function edit_note(args)
  if not args or args == "" then
    notify("ノートIDまたは番号を指定してください", vim.log.levels.ERROR)
    return
  end

  local note_id = vim.trim(args)
  if M.config.default_notebook then
    note_id = M.config.default_notebook .. ":" .. note_id
  end

  local note_path, exit_code = get_note_path(note_id)

  if exit_code ~= 0 then
    local error_msg = note_path ~= "" and note_path or "指定されたノートが見つかりません"
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

  notify("ノートを開きました: " .. note_id, vim.log.levels.INFO)
end

-- Snacks picker integration
local function snacks_nb_picker()
  local has_snacks, Snacks = pcall(require, "snacks")
  if not has_snacks then
    notify("Snacks.nvimがインストールされていません", vim.log.levels.ERROR)
    return
  end

  local notes = list_notes("")
  if not notes then
    return
  end

  -- Transform notes into picker items
  ---@type NbNoteItem[]
  local items = {}
  for _, note in ipairs(notes) do
    local note_id = note:match("^%[(.-)%]")
    if note_id then
      -- Get the full path for metadata extraction
      local path, _ = get_note_path(note_id)
      local title = note

      -- Try to extract title from file if path is valid
      if path and path ~= "" then
        local file = io.open(path, "r")
        if file then
          local first_line = file:read("*l")
          file:close()
          if first_line then
            local heading = first_line:match("^#%s+(.+)")
            if heading then
              title = "[" .. note_id .. "] " .. heading
            end
          end
        end
      end

      ---@type NbNoteItem
      local item = {
        text = title,
        note_id = note_id,
        file = path,
      }
      table.insert(items, item)
    end
  end

  -- Use Snacks picker
  Snacks.picker({
    title = "nb Notes",
    items = items,
    format = function(item)
      ---@cast item NbNoteItem
      return {
        { "📝 ", "TelescopeResultsSpecialComment" },
        { item.text, "TelescopeResultsIdentifier" },
      }
    end,
    confirm = function(_, item)
      ---@cast item NbNoteItem
      if item and item.note_id then
        vim.schedule(function()
          edit_note(item.note_id)
        end)
      end
    end,
  })
end

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
  local output, exit_code = run_nb_add(args)

  -- Handle command execution errors
  if exit_code ~= 0 then
    local error_output = sanitize_output(output)
    local message = table.concat(error_output, "\n")
    if message == "" then
      message = MESSAGES.UNKNOWN_ERROR
    end
    notify(message, vim.log.levels.ERROR)
    return
  end

  -- Extract note information from output
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

  -- Get the full path of the created note
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
  local display_message = info_line:gsub("^Added:%s*", "")
  local open_msg = MESSAGES[string.upper(M.config.open_mode) .. "_OPENED"] or MESSAGES.BUFFER_OPENED
  notify("nb add: " .. display_message .. " （" .. open_msg .. "）", vim.log.levels.INFO)
end

-- Setup function
function M.setup(opts)
  -- Merge user options with defaults
  if opts then
    M.config = vim.tbl_deep_extend("force", M.config, opts)
  end

  -- Remove existing commands if they exist
  local commands = { "NbAdd", "NbList", "NbSearch", "NbEdit", "NbPicker" }
  for _, cmd in ipairs(commands) do
    pcall(vim.api.nvim_del_user_command, cmd)
  end

  -- Create the NbAdd command
  vim.api.nvim_create_user_command("NbAdd", add_and_open_note, {
    desc = "nb add を実行して作成されたノートを開く",
    nargs = "*",
    complete = "shellcmd",
    bang = true,
  })

  -- Create the NbList command
  vim.api.nvim_create_user_command("NbList", function(cmd_opts)
    local notes = list_notes(cmd_opts and cmd_opts.args or "")
    if notes then
      -- Create a scratch buffer to display the list
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, notes)
      vim.bo[buf].buftype = "nofile"
      vim.bo[buf].bufhidden = "wipe"
      vim.bo[buf].modifiable = false

      -- Open in a split window
      vim.cmd("split")
      vim.api.nvim_win_set_buf(0, buf)

      -- Set up keymaps for the list buffer
      vim.keymap.set("n", "<CR>", function()
        local line = vim.api.nvim_get_current_line()
        local note_id = line:match("^%[(.-)%]")
        if note_id then
          vim.cmd("close")
          edit_note(note_id)
        end
      end, {
        buffer = buf,
        noremap = true,
        silent = true,
        desc = "Open note",
      })

      vim.keymap.set("n", "q", ":close<CR>", {
        buffer = buf,
        noremap = true,
        silent = true,
        desc = "Close list",
      })
    end
  end, {
    desc = "nbのノート一覧を表示",
    nargs = "*",
    complete = "shellcmd",
  })

  -- Create the NbSearch command
  vim.api.nvim_create_user_command("NbSearch", function(cmd_opts)
    local results = search_notes(cmd_opts and cmd_opts.args or "")
    if results then
      -- Create a scratch buffer to display results
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, results)
      vim.bo[buf].buftype = "nofile"
      vim.bo[buf].bufhidden = "wipe"
      vim.bo[buf].modifiable = false

      -- Open in a split window
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
      end, {
        buffer = buf,
        noremap = true,
        silent = true,
        desc = "Open note",
      })

      vim.keymap.set("n", "q", ":close<CR>", {
        buffer = buf,
        noremap = true,
        silent = true,
        desc = "Close search results",
      })
    end
  end, {
    desc = "nbでノートを検索",
    nargs = "+",
    complete = "shellcmd",
  })

  -- Create the NbEdit command
  vim.api.nvim_create_user_command("NbEdit", function(cmd_opts)
    if cmd_opts and cmd_opts.args then
      edit_note(cmd_opts.args)
    end
  end, {
    desc = "既存のnbノートを編集",
    nargs = "+",
    complete = function(arglead, _, _)
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

  -- Create the NbPicker command if Snacks picker is available
  if M.config.use_snacks_picker then
    vim.api.nvim_create_user_command("NbPicker", snacks_nb_picker, {
      desc = "Snacksピッカーでnbノートを検索",
      nargs = 0,
    })
  end
end

-- Plugin configuration
return {
  {
    name = "nb-integration",
    dir = vim.fn.stdpath("config"),
    config = function()
      M.setup()
    end,
    dependencies = {
      "folke/snacks.nvim", -- For picker functionality
    },
    keys = {
      {
        "<leader>na",
        function()
          vim.cmd("NbAdd!")
        end,
        desc = "nb add (create new note)",
        silent = true,
      },
      {
        "<leader>nl",
        function()
          vim.cmd("NbList")
        end,
        desc = "nb list notes",
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
            vim.notify("Snacksピッカー統合が無効です", vim.log.levels.WARN, { title = "nb" })
          end
        end,
        desc = "nb picker",
        silent = true,
      },
    },
  },
}
