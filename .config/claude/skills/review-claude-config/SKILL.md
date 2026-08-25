---
name: review-claude-config
description: >-
  Claude Code の skill (SKILL.md)・command・agent 定義が公式ベストプラクティスに
  沿っているかをレビューする。skill / agent / コマンド定義を新規作成・修正したとき、
  「スキルをレビューして」「エージェント定義をチェックして」などのリクエストで使用する。
  プラグイン外の個人設定 (~/.config/claude 配下) にも使える。
allowed-tools: >-
  Read, Glob, Grep, Edit, Agent, AskUserQuestion,
  Bash(claude plugin validate), Bash(claude plugin validate *),
  Bash(python3 -c *)
---

# Claude Code 定義ファイルレビュー

skill・command・agent 定義を、機械チェック + 4 観点のレビューで検証する。
外部プラグインに依存せず、この skill 単体で完結する。

## Step 1: 対象の特定と種別判定

引数・会話からレビュー対象のパスを特定する。不明なら AskUserQuestion で尋ねる
(非対話コンテキストではエラー報告して終了)。指定されたパスが存在しない・読めない
場合はその旨を報告して終了する。

複数対象が指定された場合は一覧化し、以降の Step を対象ごとに適用する。

種別判定:

- ディレクトリで `SKILL.md` がある → **skill**
- `.md` ファイルで親ディレクトリが `commands/` → **command**
- `.md` ファイルで親ディレクトリが `agents/` → **agent**
- どれでもない → その旨を報告して終了

## Step 2: 機械チェック (best-effort)

1. 対象から上方向に `.claude-plugin/plugin.json` を探し、見つかれば
   `claude plugin validate <plugin_root>` を実行する。判別基準:
   - stdout に対象ファイルの指摘ブロックがある → 指摘として保持 (exit 1 は正常動作)
   - 対象ファイルのブロックがない → 指摘なし
   - stdout に指摘形式の出力がなくエラーのみ (コマンド不在・plugin.json 破損等)
     → 手順 2 のフォールバックへ
2. プラグイン外、または validate が実行できない場合は frontmatter の YAML を
   直接パースする:

   ```bash
   python3 -c "
   import yaml, sys
   text = open(sys.argv[1]).read()
   assert text.startswith('---\n'), 'no frontmatter'
   yaml.safe_load(text.split('\n---\n', 1)[0][4:])
   " <対象ファイル>
   ```

   パース失敗は HIGH (実行時に全フィールドが黙って落ちる)。python3 はこの
   YAML パース以外に使わない
3. どちらも実行できなければ「機械チェック: スキップ (理由)」と記録して続行する

結果は「機械チェック指摘リスト」として保持し、Step 3 の各レビュアーに渡し、
Step 4 の Summary に「機械チェック」行として載せる。機械チェックの指摘は
規約準拠観点の判定に算入する。

## Step 3: 4 観点レビュー

[references/review-criteria.md](references/review-criteria.md) を Read し、
種別に対応する基準で以下の 4 観点をチェックする。references が読めない場合は
その旨を報告に明記し、本節の 4 観点名のみでベストエフォートレビューする。

1. **規約準拠**: frontmatter・命名・配置・構造
2. **プロンプト品質**: 明確性・再現性・エッジケース・例示
3. **ツール権限の安全性**: 最小権限・危険パターン
4. **設計**: 段階的読み込み・ステップ間データフロー・失敗時分岐

対象が 2 ファイル以上、または対象 + references の合計が 300 行を超える場合は、
観点ごとにサブエージェント (general-purpose) へ並列委譲する。それ以下なら
メインコンテキストで 4 観点を順にチェックしてよい。委譲時は各エージェントに
以下を渡して自己完結させる:

- 対象ファイル全文 (またはパス) と種別
- 該当観点の基準全文
- 機械チェック指摘リスト (「検出済みの項目は再指摘せず前提として扱う」と添える)

## Step 4: 結果の統合と報告

対象ごとに以下を出力し、複数対象なら最後に全対象の総合サマリ表を付ける。

```markdown
# Review: <種別> <name>

## Summary
| 観点 | 判定 (PASS/WARN/FAIL) | 指摘数 |
| 機械チェック | PASS/FAIL/SKIP | N |
| (4 観点の行) | | |

## 総合判定: PASS / NEEDS_IMPROVEMENT / FAIL

## 指摘 (優先度順)
1. [HIGH] <ファイル:行> <指摘と修正案>
...
```

判定規則 (2 段):

- **観点別**: HIGH が 1 件以上 → FAIL / HIGH なしで MEDIUM が 1 件以上 → WARN /
  それ以外 (LOW のみ・指摘なし) → PASS
- **総合**: FAIL の観点が 1 つでもあれば FAIL / WARN があれば NEEDS_IMPROVEMENT /
  全観点 PASS なら PASS (機械チェックの SKIP は PASS 扱いとし、SKIP だった旨を明記)

指摘の記載例:

```text
1. [HIGH] skills/foo/SKILL.md:3 description にトリガー条件がない →
   「〜のときに使用する」+ 対象ファイルパターンを追記
```

修正するかをユーザーに AskUserQuestion で確認し、合意した指摘のみ Edit で
反映する。非対話コンテキストではレポートのみ返し、修正しない。

## 補足: トリガー精度の計測

description のトリガー精度まで検証したい場合は、この skill ではなく
`skill-creator` の eval 機能 (evals/evals.json、should/should-not-trigger 計測)
を案内する。
