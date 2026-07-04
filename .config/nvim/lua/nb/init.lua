-- nb (https://github.com/xwmx/nb) のノートを Neovim から操作するための統合モジュール
--
-- 公開 API:
--   setup(opts)  -- 設定（nb/config.lua の defaults 参照）
--   ui:   pick / grep / add / add_select / import_image / link / move / adopt_buffer
--   core: dir / get_title / md_title / get_note_path / notebook_of / resolve_browse_url /
--         commit_and_sync / add_note / import_file / delete_note / move_note / adopt_file /
--         list_notebooks / list_all_items
local M = {}

function M.setup(opts)
  local config = require("nb.config")
  config.setup(opts)
  if config.options.autosync then
    require("nb.autosync").enable()
  end
end

return setmetatable(M, {
  __index = function(_, key)
    for _, mod in ipairs({ "nb.ui", "nb.core" }) do
      local value = require(mod)[key]
      if value ~= nil then
        return value
      end
    end
    return nil
  end,
})
