-- GitHub Projects の issue を Snacks.picker で検索するカスタムコマンド
-- ユーザーと組織のプロジェクトを統合して表示
return {
  name = "octo-project-search",
  dir = vim.fn.stdpath("config"),
  event = "VeryLazy",
  config = function()
    -- グローバルキャッシュを定義
    _G.octo_projects_cache = _G.octo_projects_cache or {
      data = nil,      -- プロジェクトのテーブル
      timestamp = 0,   -- 取得時刻 (os.time())
      ttl = 86400      -- TTL: 1日（プロジェクトは頻繁に変わらないため）
    }

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

    -- vim.uv.spawn() で gh project list を非同期実行
    local function spawn_gh_project_list(owner, callback)
      local stdout = vim.loop.new_pipe(false)
      local stderr = vim.loop.new_pipe(false)
      local stdout_data = ""
      local stderr_data = ""

      local handle
      handle = vim.uv.spawn("gh", {
        args = { "project", "list", "--owner", owner, "--limit", "100", "--format", "json" },
        stdio = { nil, stdout, stderr }
      }, function(code, signal)
        -- クリーンアップ
        stdout:close()
        stderr:close()
        handle:close()

        vim.schedule(function()
          if code == 0 then
            -- JSON パース
            local ok, data = pcall(vim.json.decode, stdout_data)
            if ok and data and data.projects then
              -- owner 情報を追加
              for _, project in ipairs(data.projects) do
                project.owner_name = owner
              end
              callback(nil, data.projects)
            else
              callback("JSON parse error", nil)
            end
          else
            callback(stderr_data, nil)
          end
        end)
      end)

      -- stdout/stderr を読み込む
      stdout:read_start(function(err, data)
        if data then stdout_data = stdout_data .. data end
      end)

      stderr:read_start(function(err, data)
        if data then stderr_data = stderr_data .. data end
      end)
    end

    -- 8個の spawn を並列起動し、すべて完了したらコールバック
    local function get_all_projects_async(callback)
      local all_projects = {}
      local errors = {}
      local pending = 0

      local function on_owner_complete(owner, err, projects)
        if err then
          table.insert(errors, string.format("%s: %s", owner, err))
        elseif projects then
          vim.list_extend(all_projects, projects)
        end

        pending = pending - 1
        if pending == 0 then
          -- すべて完了
          if #errors > 0 then
            vim.notify("一部の組織でエラー: " .. table.concat(errors, ", "), vim.log.levels.WARN)
          end
          callback(all_projects)
        end
      end

      -- ユーザーのプロジェクト
      pending = pending + 1
      spawn_gh_project_list("@me", function(err, projects)
        on_owner_complete("@me", err, projects)
      end)

      -- 組織のプロジェクト
      local orgs = get_orgs()
      for _, org in ipairs(orgs) do
        pending = pending + 1
        spawn_gh_project_list(org, function(err, projects)
          on_owner_complete(org, err, projects)
        end)
      end
    end

    -- キャッシュ付きでプロジェクトを取得
    local function get_all_projects_with_cache(callback, force_refresh)
      local cache = _G.octo_projects_cache
      local now = os.time()

      -- キャッシュチェック
      if not force_refresh and cache.data and (now - cache.timestamp) < cache.ttl then
        local age = now - cache.timestamp
        vim.notify(string.format("キャッシュを使用 (%d秒前)", age), vim.log.levels.INFO)
        callback(cache.data)
        return
      end

      -- 並列取得
      vim.notify("プロジェクト一覧を取得中...", vim.log.levels.INFO)
      get_all_projects_async(function(projects)
        -- キャッシュに保存
        cache.data = projects
        cache.timestamp = os.time()
        callback(projects)
      end)
    end

    -- Snacks.picker を使ったプロジェクト選択関数
    local function pick_project(force_refresh)
      get_all_projects_with_cache(function(projects)
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
          prompt = "GitHub Projects (User + Orgs) | <C-r> Refresh",
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
          win = {
            input = {
              keys = {
                ["<C-r>"] = {
                  function(picker)
                    picker:close()
                    pick_project(true) -- 強制リフレッシュ
                  end,
                  mode = { "n", "i" },
                  desc = "Refresh projects"
                }
              }
            }
          }
        })
      end, force_refresh)
    end

    -- カスタムコマンド: OctoSearchProject（Snacks.picker 使用）
    vim.api.nvim_create_user_command("OctoSearchProject", function()
      pick_project(false) -- 通常起動（キャッシュ使用）
    end, {
      desc = "Search issues in a GitHub project (User + Orgs)",
    })

    -- リフレッシュ用コマンド
    vim.api.nvim_create_user_command("OctoSearchProjectRefresh", function()
      pick_project(true) -- 強制リフレッシュ
    end, {
      desc = "Refresh and search GitHub projects",
    })

    -- デバッグ用コマンド: プロジェクト一覧を表示
    vim.api.nvim_create_user_command("OctoListProjects", function()
      get_all_projects_with_cache(function(projects)
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
      end, false)
    end, {
      desc = "List all GitHub projects (User + Orgs)",
    })
  end,
}
