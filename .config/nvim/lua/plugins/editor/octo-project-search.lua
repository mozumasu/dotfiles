-- GitHub Projects の issue を Snacks.picker で検索するカスタムコマンド
-- ユーザーと組織のプロジェクトを統合して表示
return {
  name = "octo-project-search",
  dir = vim.fn.stdpath("config"),
  event = "VeryLazy",
  config = function()
    -- 組織一覧を取得する関数
    local function get_orgs()
      local handle = io.popen("gh org list 2>/dev/null | awk '{print $1}'")
      if not handle then
        return {}
      end

      local result = handle:read("*a")
      handle:close()

      if not result or result == "" then
        return {}
      end

      local orgs = {}
      for org in result:gmatch("[^\r\n]+") do
        if org ~= "" then
          table.insert(orgs, org)
        end
      end

      return orgs
    end

    -- 特定の owner のプロジェクト一覧を取得する関数
    local function get_projects_for_owner(owner)
      local handle = io.popen(string.format("gh project list --owner %s --limit 100 --format json 2>&1", owner))
      if not handle then
        return {}
      end

      local result = handle:read("*a")
      handle:close()

      if not result or result == "" then
        return {}
      end

      local ok, data = pcall(vim.json.decode, result)
      if not ok or not data or type(data) ~= "table" or not data.projects then
        return {}
      end

      -- owner 情報を各プロジェクトに追加
      local projects = {}
      for _, project in ipairs(data.projects) do
        project.owner_name = owner
        table.insert(projects, project)
      end

      return projects
    end

    -- すべてのプロジェクト（ユーザー + 組織）を取得する関数
    local function get_all_projects()
      local all_projects = {}

      -- ユーザーのプロジェクトを取得
      local user_projects = get_projects_for_owner("@me")
      for _, project in ipairs(user_projects) do
        table.insert(all_projects, project)
      end

      -- 組織のプロジェクトを取得
      local orgs = get_orgs()
      for _, org in ipairs(orgs) do
        local org_projects = get_projects_for_owner(org)
        for _, project in ipairs(org_projects) do
          table.insert(all_projects, project)
        end
      end

      return all_projects
    end

    -- Snacks.picker を使ったプロジェクト選択関数
    local function pick_project()
      vim.notify("プロジェクト一覧を取得中...", vim.log.levels.INFO)

      -- 非同期的にプロジェクトを取得
      vim.schedule(function()
        local projects = get_all_projects()

        if #projects == 0 then
          vim.notify("プロジェクトが見つかりませんでした", vim.log.levels.WARN)
          return
        end

        -- Snacks.picker 用のアイテムを準備
        local items = {}
        for _, project in ipairs(projects) do
          local owner_display = project.owner_name == "@me" and "👤 Me" or ("🏢 " .. project.owner_name)
          table.insert(items, {
            text = string.format("[%s] %d - %s", owner_display, project.number, project.title),
            number = project.number,
            title = project.title,
            owner = project.owner_name,
          })
        end

        -- Snacks.picker でプロジェクトを選択
        Snacks.picker.pick({
          prompt = "GitHub Projects (User + Orgs)",
          items = items,
          format = "text",
          confirm = function(picker)
            local item = picker:current()
            if item and item.number and item.owner then
              picker:close()
              -- Octo search コマンドを実行
              local search_query = string.format("is:issue is:open assignee:@me project:%s/%s", item.owner, item.number)
              vim.cmd("Octo search " .. search_query)
            end
          end,
        })
      end)
    end

    -- カスタムコマンド: OctoSearchProject（Snacks.picker 使用）
    vim.api.nvim_create_user_command("OctoSearchProject", function()
      pick_project()
    end, {
      desc = "Search issues in a GitHub project (User + Orgs)",
    })

    -- デバッグ用コマンド: プロジェクト一覧を表示
    vim.api.nvim_create_user_command("OctoListProjects", function()
      local projects = get_all_projects()
      if #projects == 0 then
        vim.notify("プロジェクトが見つかりませんでした", vim.log.levels.INFO)
        return
      end

      local lines = { "GitHub Projects (User + Orgs):" }
      for _, project in ipairs(projects) do
        local owner_display = project.owner_name == "@me" and "👤 Me" or ("🏢 " .. project.owner_name)
        table.insert(lines, string.format("  [%s] %d: %s", owner_display, project.number, project.title))
      end

      vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
    end, {
      desc = "List all GitHub projects (User + Orgs)",
    })
  end,
}
