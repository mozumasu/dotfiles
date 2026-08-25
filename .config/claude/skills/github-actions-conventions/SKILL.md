---
name: github-actions-conventions
description: >-
  GitHub Actions workflow の runner 選択規約。workflow (.github/workflows/*.yml)
  の新規作成・修正時に必ず参照する。原則 ubuntu-slim、slim で使えないツールがある
  場合のみ ubuntu-latest にフォールバックする。
---

# GitHub Actions Runner 選択規約

## 原則

- `runs-on: ubuntu-slim` をデフォルトにする。イメージが小さく起動が速いため、
  lint・フォーマットチェックなど軽いジョブの課金分数と待ち時間を削減できる。
- 次のいずれかに該当するジョブだけ `ubuntu-latest` にフォールバックする。
  フォールバックした場合は、その理由をコミットメッセージに書く。
  - 必要なツールが slim に無く、setup 系アクションでも補いにくい
  - 実行時間・リソース要件が slim の制限を超える

## 判断フロー

1. ジョブが使うコマンド・アクションを列挙する
2. ubuntu-slim のプリインストールツールで足りるか確認する。収録内容は
   <https://github.com/actions/runner-images/blob/main/images/ubuntu-slim/ubuntu-slim-Readme.md>
   を参照し、推測で断定しない。参照できなかった場合は `ubuntu-latest` に倒し、
   未確認である旨を報告する
3. 実行時間・リソース要件を確認する。ubuntu-slim はジョブ実行時間のハード制限
   (延長不可) と低スペック (vCPU 数) の制約がある。現行の制限値は
   <https://docs.github.com/en/actions/reference/runners/github-hosted-runners>
   で確認し、ビルド・テストなど重いジョブが制限に収まるか判断する
4. ツールが足り、制限にも収まる → `ubuntu-slim`
5. ツールが足りない → まず setup 系アクション (`actions/setup-node` 等) や
   ジョブ内インストールで補えないか検討する。補うと実行時間が制限に近づく場合や、
   セットアップがジョブの大半を占める場合は `ubuntu-latest`

## 例

```yaml
jobs:
  lint:
    runs-on: ubuntu-slim
    timeout-minutes: 10

  build:
    # ジョブ実行時間が ubuntu-slim のハード制限を超えるためフォールバック
    runs-on: ubuntu-latest
    timeout-minutes: 30
```

フォールバック時のコミットメッセージ例:
`ci: 🎡 build ジョブを ubuntu-latest に変更 (実行時間が slim の制限を超えるため)`
