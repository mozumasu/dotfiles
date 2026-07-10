# Windows 側の設定

WSL の Nix/Home Manager では管理できない Windows 本体の設定。
適用は手動で 1 回だけ行う (レジストリは Home Manager の rollback では戻らないため、自動適用はしない方針)。

## マウス加速カーブ (roBa トラックボール対策)

macOS は OS が常時加速カーブをかけるため低 CPI のトラックボールでも快適だが、
Windows は「ポインターの精度を高める」ON でも加速が弱く、roBa (PMW3610, CPI=800) がもっさりする。
`SmoothMouseXCurve` / `SmoothMouseYCurve` を強め加速のカーブに書き換えて補う。

- `mouse-accel-curve.reg` — 強め加速カーブ (低速域は細かく、速く振ると大きく飛ぶ)
- `mouse-default-curve.reg` — Windows 10/11 デフォルト値 (復元用)

カーブは「ポインターの精度を高める」ON (`MouseSpeed=1`) のときだけ効くため、両ファイルとも `MouseSpeed=1` を含む。

### 適用 (WSL から)

```bash
cd ~/dotfiles/.config/windows

# 現在値のバックアップ
reg.exe export 'HKCU\Control Panel\Mouse' "$(wslpath -w ~)/mouse-backup.reg"

# 適用
reg.exe import "$(wslpath -w .)/mouse-accel-curve.reg"
```

適用後は **サインアウト → サインイン** で反映される (カーブはセッション開始時にしか読み込まれない)。

### 戻す

```bash
reg.exe import "$(wslpath -w .)/mouse-default-curve.reg"
# またはバックアップから
reg.exe import "$(wslpath -w ~)/mouse-backup.reg"
```

### 効かないとき

- `reg.exe import` が「ファイルを開けません」系のエラーを出す場合は改行コードが原因のことがある。`unix2dos *.reg` で CRLF に変換してから再実行する
- Windows の設定 → マウス → 追加のマウス設定 → ポインターオプションで「ポインターの精度を高める」が ON になっているか確認する

### 出典

- カーブ値: [Microsoft Q&A](https://learn.microsoft.com/en-us/answers/questions/1162444/how-to-further-customize-mouse-acceleration-curve) / [tweaks.com Permanent Acceleration Fix](https://tweaks.com/windows/36785/permanent-acceleration-fix/)
- デフォルト値: [sugarsweetapps.com](https://sugarsweetapps.com/blog/how-to-customize-mouse-acceleration-in-windows-11-smoothmousexcurve-and-smoothmouseycurve/)
- なお「macOS のカーブを 1:1 再現するレジストリ値」は存在しない ([LinearMouse Issue #261](https://github.com/linearmouse/linearmouse/issues/261))。将来デバイス個別に調整したくなったら [Raw Accel](https://github.com/RawAccelOfficial/rawaccel) に乗り換える
