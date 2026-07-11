# cdk mode

## Phase 1: 必ず以下を参照して、ベストプラクティスに基づいた実装を行うこと

デフォルト値から変更していないオプションは明示しないこと

- CDK の実装・デプロイ・トラブルシュート: `aws-core:aws-cdk` skill
- サービス個別の仕様確認: AWS 公式ドキュメント (docs.aws.amazon.com)
- 構成図が必要な場合: `drawio` skill

## Phase 2: デフォルト値から変更した値は根拠を.z/ディレクトリに記録すること

## Phase 3: npm run cdk:diffを実行して、変更点を確認すること
