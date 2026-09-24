# Conductor (Plot. monokey)

Conductor Studio がデバイスに保存したキーマップのバックアップ。
Studio は設定をキーボードの Flash とブラウザの LocalStorage に持つため、
リポジトリ側はスナップショットの保管だけを行う (ビルドはしない)。

## 復元手順

1. <https://studio.plotoftheprototype.com/editor> を開く
2. 右手側 (central) を USB で接続する — 左手側では Studio が応答しない
3. DevTools のコンソールで LocalStorage に流し込む

   ```js
   const b = /* keymap-backup.json の中身 */;
   localStorage.setItem('conductor-studio-keymap', JSON.stringify(b.keymap));
   localStorage.setItem('conductor-studio-combos', JSON.stringify(b.combos));
   ```

4. ページをリロードして再接続し、Write → Save

## バックアップの取り方

Studio で Read (デバイス → エディタ) してから、コンソールで:

```js
JSON.stringify({
  keymap: JSON.parse(localStorage.getItem('conductor-studio-keymap')),
  combos: JSON.parse(localStorage.getItem('conductor-studio-combos')),
})
```

## 注意

- Studio の BLE 接続には非対応。USB のみ
- `reset_conductor_*.uf2` によるリセットは左右両方に必要 (左右間のペアリングも消えるため)
