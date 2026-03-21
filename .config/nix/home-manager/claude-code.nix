{
  config,
  lib,
  pkgs,
  ...
}:
let
  dotfilesPath = "${config.home.homeDirectory}/dotfiles";
  mkLink = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/${path}";

  # 公開設定（dotfilesリポジトリにコミットされる）
  publicSettings = {
    env = {
      MAX_THINKING_TOKENS = "31999";
    };
    includeCoAuthoredBy = false;
    permissions = {
      allow = [
        "Bash"
        "Read"
        "Edit"
        "Write"
        "WebFetch"
        "mcp__context7"
        "mcp__chrome-devtools"
        "mcp__serena"
        "mcp__gemini-cli"
        "mcp__aws-cdk-mcp-server"
        "mcp__aws-documentation-mcp-server"
        "mcp__playwright"
        "mcp__mcp-google-sheets"
      ];
      deny = [
        "Bash(git push:*)"
        "Bash(rm -rf:*)"
        "Bash(sudo:*)"
        "Bash(curl:*)"
        "Bash(wget:*)"
        "Bash(chmod 777:*)"
        "Bash(> /dev:*)"
        "Bash(mkfs:*)"
        "Bash(dd:*)"
        "Bash(gh repo delete:*)"
        "Bash(gh auth logout:*)"
        "Bash(gh secret delete:*)"
        "Bash(gh variable delete:*)"
        "Bash(aws s3 rm:*)"
        "Bash(aws s3 rb:*)"
        "Bash(aws ec2 terminate-instances:*)"
        "Bash(aws rds delete-db-instance:*)"
        "Bash(aws rds delete-db-cluster:*)"
        "Bash(aws lambda delete-function:*)"
        "Bash(aws iam delete-:*)"
        "Bash(aws cloudformation delete-stack:*)"
        "Bash(aws dynamodb delete-table:*)"
        "Bash(aws sns delete-topic:*)"
        "Bash(aws sqs delete-queue:*)"
        "Bash(npm uninstall:*)"
        "Bash(npm remove:*)"
        "Bash(just apply:*)"
        "Read(.env)"
        "Read(.env.*)"
        "Read(.envrc)"
        "Read(~/.aws/**)"
        "Read(~/.ssh/id_*)"
        "Read(~/.gnupg/**)"
        "Read(./secrets/**)"
        "Read(**/credentials.json)"
        "Read(**/*token*)"
        "Edit(.env)"
        "Edit(.env.*)"
        "Edit(~/.ssh/**)"
        "Edit(~/.aws/**)"
        "Write(.env*)"
      ];
      ask = [
        "Bash(git rebase:*)"
        "Bash(git reset:*)"
        "Bash(git commit:*)"
        "Bash(gh pr create:*)"
        "Bash(gh issue create:*)"
        "Bash(gh release create:*)"
        "Bash(aws s3 cp:*)"
        "Bash(aws s3 sync:*)"
        "Bash(aws s3 mv:*)"
        "Bash(aws ec2 run-instances:*)"
        "Bash(aws ec2 start-instances:*)"
        "Bash(aws ec2 stop-instances:*)"
        "Bash(aws lambda create-function:*)"
        "Bash(aws lambda update-function-code:*)"
        "Bash(aws cloudformation create-stack:*)"
        "Bash(aws cloudformation update-stack:*)"
      ];
      additionalDirectories = [
        "~/src/github.com/mozumasu/nb"
        "~/src/github.com/mozumasu/zenn/articles"
      ];
    };
    model = "opus[1m]";
    hooks = {
      PreToolUse = [
        {
          matcher = "Bash";
          hooks = [
            {
              type = "command";
              command = "~/.config/claude/hooks/pre-bash-dispatch.sh";
            }
          ];
        }
        {
          matcher = "Write|Edit|MultiEdit";
          hooks = [
            {
              type = "command";
              command = "~/.config/claude/hooks/prevent-deprecated-tf-providers.sh";
            }
          ];
        }
        {
          matcher = "Write|Edit|MultiEdit";
          hooks = [
            {
              type = "command";
              command = "~/.config/claude/hooks/redirect-dotfiles.sh";
            }
          ];
        }
      ];
      Stop = [
        {
          matcher = "";
          hooks = [
            {
              type = "command";
              command = ''cols=$(jq -r --arg pane "$WEZTERM_PANE" 'first(.[] | select(.pane_id==($pane|tonumber)) | .size.cols) // empty' <<<"$(wezterm cli list --format=json 2>/dev/null)"); [ -n "$cols" ] || cols=$COLUMNS; [ -n "$cols" ] || cols=$(tput cols 2>/dev/null || echo 80); cols=$((cols - 10)); line=$(printf '─%.0s' $(seq 1 $cols)); echo "{\"systemMessage\": \"$line\"}"'';
            }
            {
              type = "command";
              command = ''terminal-notifier -title "Claude" -message "$(basename "$PWD")" & \nafplay /System/Library/Sounds/Glass.aiff'';
            }
          ];
        }
      ];
      Notification = [
        {
          matcher = "";
          hooks = [
            {
              type = "command";
              command = ''terminal-notifier -title "Claude Notification" -message "$(basename "$PWD")" & \nafplay /System/Library/Sounds/Glass.aiff'';
            }
          ];
        }
      ];
      PostToolUse = [
        {
          matcher = "Write|Edit|MultiEdit";
          hooks = [
            {
              type = "command";
              command = "~/.config/claude/hooks/post-write-dispatch.sh";
            }
          ];
        }
        {
          matcher = "Write|Edit|MultiEdit";
          hooks = [
            {
              type = "command";
              command = "~/.config/claude/hooks/check-tf-provider-versions.sh";
            }
          ];
        }
      ];
    };
    statusLine = {
      type = "command";
      command = "npx ccusage@latest statusline";
    };
    enabledPlugins = {
      "example-skills@anthropic-agent-skills" = true;
      "pyright-lsp@claude-plugins-official" = true;
    };
    extraKnownMarketplaces = {
      anthropic-agent-skills = {
        source = {
          source = "github";
          repo = "anthropics/skills";
        };
      };
      # 非公開マーケットプレイスは privateMarketplaces で追加
    };
    effortLevel = "high";
    plansDirectory = "./plans";
    maxTokens = 8192;
    temperature = 0;
    preferences = {
      language = "ja";
      responses = {
        concise = false;
        includeExplanations = false;
      };
    };
  };

  # 非公開マーケットプレイス設定は sops-nix で管理
  # sops.nix の claude-private-marketplaces シークレットが
  # ~/.config/claude/.private-marketplaces.json に復号配置される
  privateMarketplacesFile = "${config.xdg.configHome}/claude/.private-marketplaces.json";

  settingsFile = pkgs.writeText "claude-settings.json" (builtins.toJSON publicSettings);
in
{
  # ~/.config/claude/ 配下の読み取り専用ファイルはシンボリックリンク
  xdg.configFile = {
    "claude/CLAUDE.md".source = mkLink ".config/claude/CLAUDE.md";
    "claude/hooks".source = mkLink ".config/claude/hooks";
    "claude/skills".source = mkLink ".config/claude/skills";
    "claude/plugins".source = mkLink ".config/claude/plugins";
  };

  # ~/.claude/skills → dotfiles のスキルディレクトリ
  home.file.".claude/skills".source = mkLink ".config/claude/skills";

  # settings.json は書き込み可能なファイルとしてコピー
  # Claude Code の /config エディタが書き戻せるようにするため
  home.activation.claudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" "setupSecrets" ] ''
    SETTINGS_DIR="$HOME/.config/claude"
    mkdir -p "$SETTINGS_DIR"

    PRIVATE_FILE="${privateMarketplacesFile}"
    if [ -f "$PRIVATE_FILE" ]; then
      # 公開設定と非公開設定を jq でマージ
      ${pkgs.jq}/bin/jq -s '.[0] * .[1]' \
        "${settingsFile}" \
        "$PRIVATE_FILE" \
        > "$SETTINGS_DIR/settings.json"
      chmod 644 "$SETTINGS_DIR/settings.json"
    else
      install -Dm644 "${settingsFile}" "$SETTINGS_DIR/settings.json"
    fi
  '';
}
