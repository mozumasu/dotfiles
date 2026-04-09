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
              command = "~/.config/claude/hooks/check-settings-drift.sh";
            }
            {
              type = "agent";
              prompt = ''
                ~/.config/claude/settings.json が Nix 管理の状態から変更されていないか確認し、差分があれば適切なソースファイルに反映する。

                手順:
                1. diff <(jq -S . ~/.config/claude/settings.json) <(jq -S . ~/.config/claude/.settings.json.nix-managed) を実行して差分を確認
                2. 差分がなければ「差分なし」と報告して終了
                3. 差分がある場合、~/.config/claude/.private-marketplaces.json を読み、extraKnownMarketplaces のキー一覧からプライベートマーケットプレイス名を取得する
                4. 以下の振り分けルールに従って ~/dotfiles/.config/nix/home-manager/claude-code.nix の publicSettings を編集する:
                   - プラグイン名の @ 以降がプライベートマーケットプレイス名と一致する enabledPlugins → sops-nix (user-secrets.yaml の claude-private-marketplaces)
                   - extraKnownMarketplaces のキーがプライベートマーケットプレイス名と一致 → 同上
                   - 上記以外の enabledPlugins、extraKnownMarketplaces → claude-code.nix の publicSettings
                   - hooks、permissions、model 等その他の設定変更 → claude-code.nix の publicSettings
                   - 一時的な変更（temperature、maxTokens の微調整など）→ 無視
                5. darwin-rebuild switch の実行はユーザーに任せること（自動実行しない）
                6. 変更後はユーザーに何を変更したかと darwin-rebuild switch の実行が必要であることを報告する
              '';
            }
            {
              type = "command";
              command = ''terminal-notifier -title "Claude" -message "$(basename "$PWD")" & afplay /System/Library/Sounds/Glass.aiff'';
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
              command = ''terminal-notifier -title "Claude Notification" -message "$(basename "$PWD")" & afplay /System/Library/Sounds/Glass.aiff'';
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
    }
    // lib.optionalAttrs (builtins.pathExists privateMarketplacesFile) (builtins.fromJSON (
      builtins.readFile privateMarketplacesFile
    )).enabledPlugins;
    extraKnownMarketplaces = {
      anthropic-agent-skills = {
        source = {
          source = "github";
          repo = "anthropics/skills";
        };
      };
    }
    // lib.optionalAttrs (builtins.pathExists privateMarketplacesFile) (builtins.fromJSON (
      builtins.readFile privateMarketplacesFile
    )).extraKnownMarketplaces;
    plansDirectory = "./plans";
    maxTokens = 8192;
    temperature = 0;
    language = "ja";
    effortLevel = "medium";
  };
  };

  # 非公開マーケットプレイス設定は sops-nix で管理
  # sops.nix の claude-private-marketplaces シークレットが
  # ~/.config/claude/.private-marketplaces.json に復号配置される
  privateMarketplacesFile = "${config.xdg.configHome}/claude/.private-marketplaces.json";

  settingsFile = pkgs.writeText "claude-settings.json" (builtins.toJSON publicSettings);
in
{
  # ~/.config/claude/ は activation script で管理
  # xdg.configFile + mkOutOfStoreSymlink だと home-manager が
  # nix store 経由で dotfiles に解決した後、dotfiles 内のファイルを
  # シンボリンクで上書きし循環参照が発生するため使用しない
  home.activation.claudeFiles = lib.hm.dag.entryAfter [ "writeBoundary" "setupSecrets" ] ''
    CLAUDE_DIR="$HOME/.config/claude"
    DOTFILES="${dotfilesPath}/.config/claude"

    # ~/.config/claude が nix store へのシンボリンク（旧世代の残骸）なら削除
    if [ -L "$CLAUDE_DIR" ]; then
      rm "$CLAUDE_DIR"
    fi
    mkdir -p "$CLAUDE_DIR"

    # 読み取り専用ファイルは dotfiles へのシンボリンク
    for item in CLAUDE.md hooks scripts skills plugins; do
      if [ -L "$CLAUDE_DIR/$item" ] || [ -e "$CLAUDE_DIR/$item" ]; then
        rm -f "$CLAUDE_DIR/$item"
      fi
      ln -s "$DOTFILES/$item" "$CLAUDE_DIR/$item"
    done

    # settings.json は書き込み可能なファイルとしてコピー
    # Claude Code の /config エディタが書き戻せるようにするため
    PRIVATE_FILE="${privateMarketplacesFile}"
    if [ -f "$PRIVATE_FILE" ]; then
      ${pkgs.jq}/bin/jq -s '.[0] * .[1]' \
        "${settingsFile}" \
        "$PRIVATE_FILE" \
        > "$CLAUDE_DIR/settings.json"
      chmod 644 "$CLAUDE_DIR/settings.json"
    else
      install -Dm644 "${settingsFile}" "$CLAUDE_DIR/settings.json"
    fi

    # Nix 生成時の settings.json を参照コピーとして保存
    # Stop hook での差分検出に使用
    cp "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/.settings.json.nix-managed"
  '';

  # ~/.claude/skills → dotfiles のスキルディレクトリ
  home.activation.claudeSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    CLAUDE_HOME="$HOME/.claude"
    mkdir -p "$CLAUDE_HOME"
    if [ -L "$CLAUDE_HOME/skills" ] || [ -e "$CLAUDE_HOME/skills" ]; then
      rm -f "$CLAUDE_HOME/skills"
    fi
    ln -s "${dotfilesPath}/.config/claude/skills" "$CLAUDE_HOME/skills"
  '';
}
