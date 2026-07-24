---
name: cdk-conventions
description: >
  AWS CDK (TypeScript) でスタック・コンストラクトを書く / レビューするときのベストプラクティス集。
  「CDKでインフラを作って」「スタックを追加して」「環境(dev/stg/prod)を増やして」
  「CDKコードをレビューして」などのリクエスト、*.ts の CDK コード (bin/, lib/, Stack, Construct)
  の作成・編集・リファクタリングで必ず使用する。多環境構成・論理ID・物理名の判断を含む場合は特に必須。
---

# AWS CDK コーディング規約

AWS CDK 公式ベストプラクティスをベースにした規約。「こう書く」の列挙であり API 解説ではない。
API の詳細・最新バージョンの挙動は docs-researcher / aws-cdk スキルで引くこと。

## 基本方針

- **決定は synth 時に済ませる**。CloudFormation の `Fn::If`/Conditions は使わず、
  TypeScript の条件分岐で synth 結果を確定させる
- **L2 コンストラクトを第一選択**にする。L2 が無い場合のみ L1 (`Cfn*`)。
  L2 に無いプロパティは `node.defaultChild` → `addPropertyOverride` の順でエスケープ
- L3 (複数リソースを束ねた高級コンストラクト) を使う前に、何がプロビジョンされるか
  `cdk synth` で必ず確認する

## 多環境構成: 分岐は config 層に集める

**環境の違いは「データ (config)」で表現し、リソース定義の中で環境名を比較しない。**

| 層 | 環境名での分岐 |
|---|---|
| エントリポイント (`bin/`) の config 選択 | ✅ 唯一の `switch (envName)` の置き場 |
| config ファイル | 分岐不要 (環境ごとに値をベタ書き) |
| Stack / Construct | ❌ `if (envName === 'dev')` を書かない |

- config は環境ごとに 1 ファイル (`config/dev.ts`, `config/prod.ts`) とし、
  共通の `Config` 型を満たす形で **値をすべて明示的にベタ書き**する。
  「prod だけ 2 台」のような差は config の数値で表現する
- リソースの有無は **config のオプショナル項目の有無**で分岐する:

  ```ts
  // ✅ 機能の ON/OFF は config の値の有無で判定
  if (props.config.redis) {
    new elasticache.CfnCacheCluster(this, 'Redis', {
      cacheNodeType: props.config.redis.nodeType,
    });
  }

  // ❌ 環境名の比較。新環境 (dev-1 等) がどの分岐にも落ちず壊れる
  if (envName === 'dev' || envName === 'stg') { ... }
  ```

- ❌ `dev ? 512 : stg ? 1024 : 2048` のような環境名の三項演算子チェーンも同罪。
  値そのもの (`config.ecs.cpu`) を config に持たせる
- 例外: リージョン・パーティションなど **AWS 側の制約**による分岐はコード側に書いてよい
  (例: CloudFront 用証明書は us-east-1 のみ)
- `env: { account, region }` はスタックに必ず明示指定する (環境 agnostic スタックを作らない)
- 環境選択は `-c env=dev` の context 経由とし、未知の環境名は `throw` で弾く

## 論理IDの安定性

**論理IDが変わる = リソースの削除+再作成。** ステートフルリソースではデータ喪失になる。

- デプロイ済みコンストラクトの **ID (第2引数) と階層を変えない**。
  リファクタで移動する場合は `cdk refactor` か `renameLogicalId()` で論理IDを維持する
- ID は役割を表す簡潔な PascalCase (`Database`, `ApiHandler`)。
  型名の重複 (`BucketBucket`) や環境名の埋め込みはしない
- L3 内の主リソースは ID `Default` の慣習に従う
- デプロイ前に必ず `cdk diff` し、意図しない **削除+追加のペア** (= 置換) がないか確認する

## 物理名

- **物理名 (bucketName, tableName, functionName 等) は原則指定しない**。
  CDK の自動生成名に任せる (論理ID変更時の衝突・置換失敗を避ける)
- クロススタック/クロスアプリ参照等でやむを得ず指定する場合は
  **必ず環境名を含める** (`${projectName}-${envName}-...`)。
  環境名を含まない物理名は同一アカウントに 2 環境目を作った時点で衝突する
- SSM パラメータ名・ECR リポジトリ名も同様に環境名を含める

## スタック分割

- **ステートフルリソース (DB, S3, ECR) はステートレスと別スタック**にし、
  `terminationProtection: true` を付ける
- 全リソースに `removalPolicy` を明示する。開発環境の S3 を destroy で消したい場合は
  `removalPolicy: DESTROY` + `autoDeleteObjects: true` の両方が必要
- スタック名は `` `${StackName}-${envName}` `` 形式で環境ごとに分離する
- クロススタック参照は同一 app なら **props でコンストラクト参照を渡す** (自動 export/import)。
  参照を削除するときは deadly embrace に注意し 2 段階デプロイ
  (producer に `exportValue()` 追加 → 次のデプロイで削除)
- 循環参照は共有リソースを第 3 のスタックへ抽出して解消する

## IAM / セキュリティ

- リソース間の権限は **`grant*()` メソッド**で付与する (`bucket.grantRead(fn)`)。
  手書き PolicyStatement は grant で表現できない場合のみ
- CI/CD の認証は OIDC (静的キー禁止)
- `cdk-nag` (`AwsSolutionsChecks`) を app に適用し、抑制は `NagSuppressions` +理由コメントで最小限に

## テスト

- `Template.fromStack()` の fine-grained assertion を基本にする。
  柔軟なマッチは `Match.objectLike` / `Match.anyValue`
- スナップショットテストは差分検知の補助のみ (単独のテスト戦略にしない)
- **重要なステートフルリソースは論理IDの安定性をテストで固定する**
  (`template.hasResource` で論理IDを assert)
- config 変更が意図したリソース差分だけを生むか、環境ごとに synth してテストする

## ワークフロー

- `cdk synth --strict` → `cdk diff` → `cdk deploy` の順。prod への diff なしデプロイ禁止
- `cdk.context.json` はコミットする (lookup 結果の再現性)
- デプロイ失敗時は CDK のエラーではなく CloudFormation イベントを見る:
  `aws cloudformation describe-stack-events --stack-name $STACK --query "StackEvents[?contains(ResourceStatus,'FAILED')]"`
