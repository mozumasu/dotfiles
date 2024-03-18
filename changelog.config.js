module.exports = {
  disableEmoji: false,
  format: '{type}{scope}: {emoji}{subject}',
  list: ['feat', 'test', 'fix', 'chore', 'docs', 'refactor', 'style', 'ci', 'perf', 'package', 'config'],
  maxMessageLength: 64,
  minMessageLength: 3,
  questions: ['type', 'scope', 'subject', 'body', 'breaking', 'issues', 'lerna'],
  scopes: [],
  types: {
    feat: {
      description: '新機能',
      emoji: '🎸',
      value: 'feat'
    },
    chore: {
      description: 'ビルド関連やライブラリの変更',
      emoji: '🤖',
      value: 'chore'
    },
    ci: {
      description: 'CI関連の変更',
      emoji: '🎡',
      value: 'ci'
    },
    docs: {
      description: 'ドキュメントの更新',
      emoji: '✏️',
      value: 'docs'
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
      description: 'リファクタリング',
      emoji: '💡',
      value: 'refactor'
    },
    style: {
      description: 'コードの処理に影響しない変更（スペースや書式設定など)',
      emoji: '💄',
      value: 'style'
    },
    test: {
      description: 'テストコード',
      emoji: '💍',
      value: 'test'
    },
    //自分用に追加
    package: {
      description: 'パッケージ',
      emoji: '📦',
      value: 'package',
    },
    config: {
      description: '設定ファイル',
      emoji: '⚙',
      value: 'config',
    }

  },
    messages: {
      type: 'プレフィックスを選択してね:',
      customScope: 'コミットが影響するスコープを選択してね:',
      subject: 'コミットのタイトル（概要）を入力してね:\n' ,
      body: '変更内容の詳細があれば入力してね:\n',
      breaking: '重大な変更があれば入力してね:\n',
      issues : '解決したissueがあれば入力してね, 例 #123:',
      confirmCommit: 'このコミットが影響するパッケージがあれば入力してね:',
  },
};
