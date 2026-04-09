---
paths:
  - "**/*.tf"
  - "**/terraform/**"
  - "**/*.hcl"
---

# インフラ変更時のドキュメント参照ポリシー

- AWS・GCPリソースの変更時は、**実装前に公式ドキュメントを確認**すること
  - AWS: docs.aws.amazon.com、registry.terraform.io
  - GCP: cloud.google.com、registry.terraform.io
- **PR説明文（pr.md）には `## References` セクションを設け、根拠となる公式ドキュメントURLを必ず記載すること**
