module.exports = {
  disableEmoji: false,
  format: '{type}{scope}: {emoji}{subject}',
  list: ['test', 'feat', 'fix', 'chore', 'docs', 'refactor', 'style', 'ci', 'perf'],
  maxMessageLength: 64,
  minMessageLength: 3,
  questions: ['type', 'scope', 'subject', 'body', 'breaking', 'issues', 'lerna'],
  scopes: [],
  types: {
    chore: {
      description: 'ドキュメントの生成やビルドプロセス、ライブラリなどの変更',
      emoji: '🤖',
      value: 'chore'
    },
    ci: {
      description: 'CI用の設定やスクリプトに関する変更',
      emoji: '🎡',
      value: 'ci'
    },
    docs: {
      description: 'ドキュメントのみの変更',
      emoji: '✏️',
      value: 'docs'
    },
    feat: {
      description: '新機能',
      emoji: '🎸',
      value: 'feat'
    },
    fix: {
      description: '不具合の修正',
      emoji: '🐛',
      value: 'fix'
    },
    perf: {
      description: 'パフォーマンス改善',
      emoji: '⚡️',
      value: 'perf'
    },
    refactor: {
      description: 'バグ修正や機能の追加を行わないコードの変更',
      emoji: '💡',
      value: 'refactor'
    },
    style: {
      description: 'コードの処理に影響しない変更（スペースや書式設定など',
      emoji: '💄',
      value: 'style'
    },
    test: {
      description: 'テストコードの変更',
      emoji: '💍',
      value: 'test'
    },
    messages: {
      type: 'プレフィックスを選択してね',
      customScope: 'Select the scope this component affects:',
      subject: 'コミットのタイトル（概要）を入力してね',
      body: 'コミットの詳細を入力してね',
      breaking: '重大な変更をリストに追加する？',
      footer: '解決したissueがあれば入力してね, 例 #123:',
      confirmCommit: 'このコミットが影響するパッケージがあれば入力してね',
    },
  }
};
