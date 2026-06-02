# Raycast Today Suite

Raycast から「今日の自分の動き」をクリップボードにコピーする一連の Script Command。

## スクリプト

| Raycast コマンド | 出力 | スクリプト |
| --- | --- | --- |
| **Today's Calendar** | 今日と明日の Calendar.app 予定 | `today-calendar.sh` |
| **Today's GitHub** | 今日 close した issue (assignee:@me) | `today-github.sh` |
| **Today's Summary** | 上記2つを結合 | `today-summary.sh` |
| **Free Time Slots** | 指定日の空き時間スロット | `free-time-slots.sh` |

`Summary` は内部で `NO_PBCOPY=1` を立てて他 2 つを呼び出し、結合した結果を一度だけ `pbcopy` する。

## 出力例 (Today's Summary)

```text
Today May 12
10:30 - 11:00  開発チーム朝会
13:00 - 14:00  ワークショップ
16:00 - 17:00  もくもく会

Tomorrow May 13
10:30 - 11:00  開発チーム朝会
16:00 - 17:00  もくもく会

GitHub Closed Today (2026-XX-XX)
[org/repo#1] Takumi Ruuner/Guardの検証
```

## 構成

| ファイル | 役割 |
| --- | --- |
| `.config/raycast/scripts/today-calendar.sh` | Calendar Script Command 本体 |
| `.config/raycast/scripts/today-github.sh` | GitHub Script Command 本体 |
| `.config/raycast/scripts/today-summary.sh` | 上記 2 つをまとめて呼び出すアグリゲータ |
| `.config/nix/home-manager/sops.nix` | host 別に `INCLUDE_CALS` を `~/.config/local/today-calendar.conf` へ復号配置 |
| `.config/nix/secrets/user-secrets.yaml` | `today-calendar-conf-work` / `today-calendar-conf-personal` を sops で暗号化保存 |
| `.config/nix/hosts/common/homebrew.nix` | `ical-buddy` を brew 経由でインストール |
| `.config/nix/home-manager/dotfiles.nix` | `~/.config/raycast/scripts` を dotfiles に symlink |

## 依存

- [ical-buddy](https://hasseg.org/icalBuddy/) (Homebrew 経由、Calendar.app の予定を CLI で取得)
- [gh](https://cli.github.com/) (home-manager で導入済、`gh auth login` 必要)
- [sops-nix](https://github.com/Mic92/sops-nix) (個人情報の暗号化管理)
- Raycast

## セットアップ（新規マシン）

### 1. sops で `user-secrets.yaml` を編集

```sh
nix shell nixpkgs#sops -c sops ~/dotfiles/.config/nix/secrets/user-secrets.yaml
```

トップレベルに work / personal 両方のキーを追加:

```yaml
today-calendar-conf-work: |
  INCLUDE_CALS="<work-email>"
today-calendar-conf-personal: |
  INCLUDE_CALS="<personal-email>"
```

`hostSpec.isWork` の値によりどちらか一方が `~/.config/local/today-calendar.conf` へ復号配置される。

### 2. home-manager 反映

```sh
~/dotfiles/mozumasu.sh
```

これで以下が同時に揃う:

- `ical-buddy` が brew でインストール
- `gh` が PATH 上に
- `~/.config/raycast/scripts` が dotfiles に symlink
- `~/.config/local/today-calendar.conf` が sops から復号配置

### 3. `gh` 認証

```sh
gh auth login
gh auth status   # 認証済みであることを確認
```

### 4. Raycast にスクリプトディレクトリを登録

1. Raycast → `Cmd+,` で Settings
2. **Extensions** タブ → **Script Commands**
3. **Add Directory** で `~/.config/raycast/scripts` を追加

`Today's Calendar` / `Today's GitHub` / `Today's Summary` がコマンド一覧に表示されれば成功。

### 5. Calendar.app へのアクセス許可（TCC）

初回実行時に macOS が Calendar アクセス許可を求める。一度ターミナルから叩いて許可を取っておくと確実:

```sh
icalBuddy eventsToday
# → macOS のダイアログで "OK" を選択
```

## カスタマイズ

各スクリプトの該当箇所を編集して即反映（symlink なので home-manager 再実行不要）。

### Calendar

| 用途 | 変更箇所 (`today-calendar.sh`) |
| --- | --- |
| 期間を延ばす | `eventsToday+1` → `eventsToday+6` (1週間) |
| 終日予定を除外 | `ical_args=(...)` に `--excludeAllDayEvents` を追加 |
| 出力フォーマット変更 | 末尾の `awk` ブロックを編集 |
| 含めるカレンダー変更 | `~/.config/local/today-calendar.conf` の `INCLUDE_CALS` を編集 (sops 経由) |

### GitHub

| 用途 | 変更箇所 (`today-github.sh`) |
| --- | --- |
| 対象を `author` に変更 | `--assignee=@me` → `--author=@me` |
| 期間変更 | `closed:>=${today}` を `closed:${start}..${end}` 形式に |
| PR も含める | `gh search prs` を別途呼び出すブロックを追加 |
| 件数上限変更 | `--limit=100` の値 |

## トラブルシューティング

### `icalBuddy が見つかりません`

`brew install ical-buddy` がまだ走ってない。home-manager switch が完了しているか確認。

### `gh CLI 未認証`

`gh auth login` を実行。Raycast から起動する場合も同じ認証状態が共有される。

### Raycast 経由でだけ `(github fetch failed)` が出る

Raycast Script Commands は launchd 由来の最小 PATH で起動するため、nix 管理の `gh`
(`/etc/profiles/per-user/$USER/bin/gh`) が見つからずに落ちることがある。`today-github.sh`
では冒頭で `PATH` に nix 関連ディレクトリを明示追加しているため、新しく nix-managed
バイナリに依存するスクリプトを増やすときは同じ prelude を入れる必要がある。

### 重複した予定が出る

`INCLUDE_CALS` でフィルタしたいカレンダー名を絞る。利用可能なカレンダー名は `icalBuddy calendars` で一覧できる。

### Raycast から実行しても何も起きない

- `~/.config/raycast/scripts` が Raycast の Script Commands ディレクトリに登録されているか確認
- 該当スクリプトの実行権限を確認 (`chmod +x`)
- ターミナルから直接スクリプトを実行して挙動確認

### Calendar.app の権限を聞かれない / アクセス拒否

`System Settings → Privacy & Security → Calendars` で Raycast.app（とターミナル）が許可されているか確認。

### 単体スクリプトの動作確認 (clipboard 汚染を避ける)

```sh
NO_PBCOPY=1 ~/.config/raycast/scripts/today-calendar.sh
NO_PBCOPY=1 ~/.config/raycast/scripts/today-github.sh
```

`NO_PBCOPY=1` を立てると `pbcopy` をスキップして stdout のみ出力する。Summary もこのフラグを使って内部呼び出ししている。
