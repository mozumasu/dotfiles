---
name: rego-writing
description: >
  OPA の Rego 言語でポリシーを書く・レビューする・デバッグするときの記法と落とし穴。
  「Rego を書いて」「OPA のポリシーを作って」「conftest のルールを追加して」「この rego を
  レビューして」などのリクエスト、*.rego ファイルの作成・編集・レビューで必ず使用する。
  「deny が出ない」「ポリシーが効いていない」「テストが通らない」といった Rego の
  デバッグ相談、Rego の記法・セマンティクスの質問(not の挙動、undefined、キー欠落)にも使う。
---

# Rego Writing

OPA / conftest / Gatekeeper で使う Rego 言語の書き方。
Rego は普通の言語の直感が通用しない箇所が多く、しかも**壊れてもエラーを出さない**ため、
セマンティクスの理解とテスト規律がセットで必要になる。

## メンタルモデル: 手続きではなく「条件の宣言」

Rego は上から実行する手順書ではなく「この条件を全部満たすものを探して」と宣言する言語
(SQL に近い)。基本形:

```rego
package main

import rego.v1

deny contains msg if {
	条件1        # ルール内の各行は AND
	条件2
	msg := "..."  # 全条件成立時に deny 集合へ msg を追加
}
```

- **ルール内の改行 = AND、同名ルールの複数定義 = OR**
- conftest 等の合否は「deny 集合が空か」で決まる。「合格判定」ではなく**違反の列挙**を書く
- `some rc in input.resource_changes` が for ループの代わり。全要素が自動で試され、
  条件を満たした要素ごとに msg が生成される

記号の使い分け: `:=`(代入)と `==`(比較)だけ使う。裸の `=`(単一化)は避ける。

## 最重要のセマンティクス: 失敗が静か (silent pass)

普通の言語なら例外になる状況(存在しないキーの参照、条件不成立)が、Rego では
エラーにならず「**そのルールの評価が黙って不成立になる**」だけ。帰結:

- タイポ・キー名間違い・ロジックミスでポリシーが死んでいても、deny が空になるだけで
  **CI は「違反ゼロ」と同じ顔で緑になる**。壊れたことに気づく仕組みが言語側にない
- したがって「deny が発火するテスト」が唯一の検出器になる(下記テスト規律)

デバッグで「deny が出ない」ときは、まずどの行で評価が不成立になっているかを疑う。
[Rego Playground](https://play.openpolicyagent.org/) に入力とポリシーを貼り、
中間ルールを個別に評価すると切り分けが速い。

## 落とし穴: negation 巻き上げ (実バグの定番)

```rego
# ダメな例: キー欠落時に deny が出ない (fail-open)
deny contains msg if {
	some rc in vpc_creations
	not is_string(rc.change.after.cidr_block)   # ← バグ
	msg := ...
}
```

見た目は「文字列でなければ deny」だが、OPA はコンパイル時に参照を `not` の外へ巻き上げる:

```rego
	__tmp__ := rc.change.after.cidr_block  # キーが無いとこの代入が不成立
	not is_string(__tmp__)                 # ここに到達しない → ルールごと消える
```

`after` に `cidr_block` キーが**存在しない**場合(null が入っている場合ではない)、
代入が不成立 → ルール全体が静かに消え、本来 deny したい「値が未確定」が素通りする。

**対策: 欠落チェックには必ず `object.get` を使う。**

```rego
deny contains msg if {
	some rc in vpc_creations
	cidr := object.get(rc.change, ["after", "cidr_block"], null)  # 欠落を null に変換
	not is_string(cidr)                                            # 必ず判定に到達する
	msg := ...
}
```

`object.get` は「見つからなければ第 3 引数を返す」ため代入が空振りしない
(ただし第 1 引数自体が未定義なら不成立になる点は同じ。第 1 引数は存在が保証された
階層を渡し、不確かな部分をパス配列側に置く)。

## 原則: fail-closed

検証ゲートでは「値が欠落/未確定 = 検証できない」を「違反ではない」ではなく
**deny に倒す**。Terraform plan なら `after_unknown` のフィールド、K8s なら
省略可能フィールドが該当する。fail-open は上記の巻き上げバグで無自覚に発生しやすい。

## conftest の予約ルール名: deny / violation / warn

conftest は `deny` だけでなく **`violation` と `warn` も違反ルールとして直接報告する**。
deny への変換前の中間集合に `violation` と名付けると、conftest が中間集合を直接拾って
FAIL にしてしまい、後段の変換 (免除判定など) が素通りされる (実測で確認済みの罠)。
中間集合には予約語以外の名前 (`finding` 等) を使う。

## 免除・集約は共通 deny 1 箇所に集める

「各 deny ルールが免除ヘルパーを呼ぶ」規約は、呼び忘れ 1 箇所で allowlist が静かに
無効化される (silent pass なのでエラーも出ない)。人間の規約ではなく構造で防ぐ:

```rego
# 各ポリシー: deny を書かず、構造化した finding を列挙するだけ
finding contains v if {
	<検査条件>
	v := {"path": ..., "rule": "<識別子>", "msg": ...}
}

# 共通側 (1 箇所だけ): 免除判定を経て deny に変換
deny contains v.msg if {
	some v in finding
	valid_finding(v)
	not excepted(v.path, v.rule)
}

# fail-closed: 形が不正な finding は免除判定できないため deny に倒す
deny contains msg if {
	some v in finding
	not valid_finding(v)
	msg := sprintf("不正な finding: %v", [v])
}
```

- finding ルールが 1 本も無くても deny がコンパイルできるよう、空の種
  (`finding contains v if { some v in [] }`) を共通側に置く (未定義参照はコンパイルエラー)
- 「共通ファイル以外での deny / violation / warn 定義を禁止」を CI の grep で機械検査すると
  抜け道も塞げる
- conftest 組み込みの `exception` ルールは評価 1 回分にしか効かないため、`--combine`
  (全ファイルを 1 入力に束ねる) と併用すると 1 ファイル単位の免除ができない。
  combine するなら免除は自前で持つ

## テスト規律: 最小 3 ケース

`*_test.rego` に、コードパスごとに 1 件だけ書く。網羅はしない
(境界値バリエーションや対称ケースは同じコードパスの別入力で、保守コストに見合わない):

1. **準拠入力が pass** — 誤爆しない (厳しすぎ方向の壊れ検知)
2. **違反入力が deny** — ポリシーが生きている (緩すぎ方向の壊れ検知)
3. **欠落/未確定入力が deny** — fail-closed の回帰防止

```rego
test_out_of_range_denied if {
	count(deny) == 1 with input as {"resource_changes": [{ ... }]}
}
```

- `with input as <モック>` で入力を注入し、`count(deny) == N` の**完全一致**で比較する
  (`count(deny) > 0` は複数ルールの誤発火を見逃す)
- テストが 1 つもない Rego は「壊れても緑に見える」状態で運用されることになる。
  レビューではテスト不在を必ず指摘する
- 実行: `conftest verify -p <policy dir>` または `opa test`

## deny メッセージの書き方

deny メッセージは CI の赤バツでユーザーが読む文。「何がダメか」だけでなく
「**どうすれば通るか**」を書く:

```rego
msg := sprintf("%s: VPC CIDR %q は割当標準外です。10.0.0.0/12 内の /16 を使用してください", [rc.address, cidr])
```

## レビュー観点チェックリスト

Rego をレビューするときは以下を機械的に確認する:

- [ ] `not` + ネスト参照の組み合わせがないか (巻き上げ fail-open)
- [ ] 欠落・未確定値が fail-closed になっているか
- [ ] deny が発火するテストが存在するか (準拠 pass / 違反 deny / 欠落 deny)
- [ ] 検査対象の抽出条件は適切か (例: Terraform なら `"create" in actions` は
      replace の `["delete","create"]` も拾う。update を含めるかは要件次第)
- [ ] プレフィックス比較の末尾 (`"db.t4g"` は `db.t4gx` も通す → `"db.t4g."`)
- [ ] conftest 利用時、中間集合に `violation` / `warn` の名前を使っていないか (直接報告される)
- [ ] deny メッセージに修正方法が書かれているか
- [ ] ルールの根拠 (社内標準・ドキュメント) がコメントに残っているか。
      標準の一般化 (例: 割当表 → /12 レンジ) は解釈であることを明記

## 入力データの確認を先にやる

ポリシーを書く前に、実際の入力 JSON を必ず見る (`terraform show -json tfplan | jq`、
`kubectl get -o json` 等)。フィールド名・ネスト構造・null と欠落の区別を推測で書くと、
silent pass のせいで間違いに気づけない。Terraform plan なら
`input.resource_changes[].change` の `actions` / `after` / `after_unknown` が主な検査対象。
