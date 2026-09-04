---
name: tech-scrap
description: 現在のセッションの内容を匿名化した技術スクラップとして ~/src/github.com/mozumasu/nb/home に保存する
disable-model-invocation: true
context: fork
allowed-tools: Read, Write, Edit, Glob, WebFetch, Bash(ls *)
argument-hint: "[追加の指示]"
---

このセッションでここまでに扱った内容を、技術スクラップとして `~/src/github.com/mozumasu/nb/home` に保存する。
nb は自動コミットされるためコミット不要。

追加の指示 (空なら無視): $ARGUMENTS

執筆ルールは @${CLAUDE_SKILL_DIR}/scrap-rules.md に従う。

## 手順

1. トピックを表す簡潔なファイル名を決める (例: `crane.md`, `ecs-exec.md`)。
2. `nb/home` に同じトピックのファイルがあるか Glob で探す。
   - あれば既存の記述を残したまま追記・明らかな誤りの訂正のみ行う。
   - なければ新規作成する。
3. 本文に含める URL を WebFetch で到達確認する。到達できなかった URL は残したうえで直後に `(リンク切れ確認: YYYY-MM-DD)` と注記する。
4. 保存後、親には保存したファイルのパスと 1 行の要約だけを返す。本文は返さない。
