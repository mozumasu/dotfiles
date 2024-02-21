# スクリプトメモ
実際に使用したスクリプトを管理

## Apple musicが勝手に立ち上がらないようにする
無効化
```
launchctl disable gui/"$(id -u)"/com.apple.rcd
launchctl kill SIGTERM gui/"$(id -u)"/com.apple.rcd
```

有効化
```
launchctl enable gui/"$(id -u)"/com.apple.rcd
launchctl kickstart gui/"$(id -u)"/com.apple.rcd
```