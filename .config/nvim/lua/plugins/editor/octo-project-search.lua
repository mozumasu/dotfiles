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

    -- 組織一覧を取得する関数（タイムアウト5秒でハング防止）
    local function get_orgs()
      local result = vim.system({ "gh", "org", "list" }, { text = true, timeout = 5000 }):wait()
      if result.code ~= 0 or not result.stdout or result.stdout == "" then
        return {}
      end
      local orgs = {}
      for line in result.stdout:gmatch("[^\r\n]+") do
        local org = line:match("^(%S+)")
        if org and org ~= "" then
          table.insert(orgs, org)
        end
      end
      return orgs
    end

    -- 現在のリポジトリオーナーを同期取得
    local function get_repo_owner()
      local result = vim.system(
        { "gh", "repo", "view", "--json", "owner" },
        { text = true, timeout = 5000 }
      ):wait()
      if result.code ~= 0 or not result.stdout or result.stdout == "" then
        return nil, "gh repo view に失敗しました: " .. (result.stderr or "")
      end
      local ok, data = pcall(vim.json.decode, result.stdout)
      if not ok or not data or not data.owner or not data.owner.login then
        return nil, "オーナー情報のパースに失敗しました"
      end
      return data.owner.login, nil
    end

    -- gh project item-list を非同期実行してIssueのみ返す
    local function fetch_project_items(owner, project_number, callback)
      local stdout = vim.uv.new_pipe(false)
      local stderr = vim.uv.new_pipe(false)
      local stdout_data = ""
      local stderr_data = ""

      local handle
      handle = vim.uv.spawn("gh", {
        args = { "project", "item-list", tostring(project_number), "--owner", owner, "--format", "json", "--limit", "100" },
        stdio = { nil, stdout, stderr }
      }, function(code, _signal)
        stdout:close()
        stderr:close()
        handle:close()

        vim.schedule(function()
          if code == 0 then
            local ok, data = pcall(vim.json.decode, stdout_data)
            if ok and data and data.items then
              local issues = {}
              for _, item in ipairs(data.items) do
                if item.content and item.content.type == "Issue" then
                  table.insert(issues, item)
                end
              end
              callback(nil, issues)
            else
              callback("JSON parse error", nil)
            end
          else
            callback(stderr_data, nil)
          end
        end)
      end)

      stdout:read_start(function(_err, data)
        if data then stdout_data = stdout_data .. data end
      end)

      stderr:read_start(function(_err, data)
        if data then stderr_data = stderr_data .. data end
      end)
    end

    -- Snacks.picker でプロジェクトのissue一覧を表示
    local function open_project_issues(owner, project_number)
      vim.notify(string.format("Project #%d のissueを取得中...", project_number), vim.log.levels.INFO)
      fetch_project_items(owner, project_number, function(err, issues)
        if err then
          vim.notify("issueの取得に失敗しました: " .. err, vim.log.levels.ERROR)
          return
        end
        if not issues or #issues == 0 then
          vim.notify("issueが見つかりませんでした", vim.log.levels.WARN)
          return
        end

        local items = {}
        for _, item in ipairs(issues) do
          local content = item.content
          local status = item.status or ""
          local icon
          if status == "Done" or status == "Closed" then
            icon = "✓"
          elseif status == "In Progress" then
            icon = "●"
          else
            icon = "○"
          end

          -- リポジトリ名の取得（content.repository は "owner/repo" 形式のためリポジトリ名のみ抽出）
          local repo_name = nil
          if content.repository then
            -- "owner/repo" → "repo"
            repo_name = content.repository:match("/(.+)$") or content.repository
          elseif content.url then
            -- https://github.com/<owner>/<repo>/issues/<number>
            repo_name = content.url:match("github%.com/[^/]+/([^/]+)/issues/")
          end

          table.insert(items, {
            text = string.format("%s #%d %s [%s]", icon, content.number, content.title, status),
            number = content.number,
            title = content.title,
            repo = repo_name,
            owner_login = owner,
            url = content.url,
          })
        end

        Snacks.picker.pick({
          prompt = string.format("Project #%d Issues (%s)", project_number, owner),
          items = items,
          format = "text",
          confirm = function(picker)
            local selected = picker:current()
            if selected then
              picker:close()
              local repo = selected.repo
              if not repo and selected.url then
                repo = selected.url:match("github%.com/[^/]+/([^/]+)/issues/")
              end
              if repo then
                vim.cmd(string.format("edit octo://%s/%s/issue/%d", selected.owner_login, repo, selected.number))
              else
                vim.notify("リポジトリ名を特定できませんでした: " .. (selected.url or "URL不明"), vim.log.levels.ERROR)
              end
            end
          end,
        })
      end)
    end

    -- vim.uv.spawn() で gh project list を非同期実行
    local function spawn_gh_project_list(owner, callback)
      local stdout = vim.uv.new_pipe(false)
      local stderr = vim.uv.new_pipe(false)
      local stdout_data = ""
      local stderr_data = ""

      local handle
      handle = vim.uv.spawn("gh", {
        args = { "project", "list", "--owner", owner, "--limit", "100", "--format", "json" },
        stdio = { nil, stdout, stderr }
      }, function(code, _signal)
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
      stdout:read_start(function(_err, data)
        if data then stdout_data = stdout_data .. data end
      end)

      stderr:read_start(function(_err, data)
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

    -- カスタムコマンド: OctoProject（番号指定でissue一覧を表示）
    vim.api.nvim_create_user_command("OctoProject", function(opts)
      local project_number = tonumber(opts.args)
      if not project_number then
        vim.notify("使用方法: :OctoProject <number>  例: :OctoProject 19", vim.log.levels.ERROR)
        return
      end
      local owner, err = get_repo_owner()
      if not owner then
        vim.notify("リポジトリオーナー取得エラー: " .. (err or "不明"), vim.log.levels.ERROR)
        return
      end
      open_project_issues(owner, project_number)
    end, {
      nargs = 1,
      desc = "Open project issues in Snacks.picker (auto-detects repo owner)",
    })

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
