# キーバインド覚えられない無理すぎ
キーバインド覚えられ無さすぎるのでチートシート作成
- [vim](/.config/nvim/lua/keybinds.lua)
- [alias]()
## tmux
設定ファイル：`~/.tmux.conf`  
Prefix： Ctrl + G に設定
### tmux session
| キー | 内容 |
| --- | --- |
| tmux | 起動 |
| Control + g d | デタッチ |
| tmux ls | セッション一覧 |
| tmux a -t セッション名 | アタッチ |
| Control + g s => 0 or 1 | セッション一覧から選択 |
| tmux kill-server | tmuxシャットダウン |
| Control + g t | 時計を表示 |

### tmux pane
| キー | 内容 |
| --- | --- |
| `Control + g` → \ | 横(左右)に分ける |
| `Control + g` → - | 縦(上下)に分ける |
| `Control + g` x or Control d (通常terminal exit) | ペイン破棄 |
| `Control + g` `z` | ペイン拡大 /縮小 |
| `Control + g` `o` | 次のペインに移動 |
| `Control + g` `←→↑↓` | ペインを移動 |
| `Control + g` ` { ` | ペインの順序を前方向に入れ替え |
| `Control + g` ` } ` | ペインの順序を後方向に入れ替え |
| `Control + g` `space` | レイアウトの変更 |
| `Control + g` + `q` → `数字` | ペインの番号表示から移動 |

### tmux windows
windows
| キー | 内容 |
| --- | --- |
| Control + g c | 新規ウィンドウ |
| Control + g n | 次のウィンドウ |
| Control + g p | 前のウインドウ |
| Control + g 数字 | 指定番号のウィンドウに移動 |
| Control + g & | ウインドウを破棄する |
| Control + g , | ウインドウの名前を変える |

### tmux copy
Control + g [ → 移動(jklh) → v → 移動(jklh) → y → enter → Command + v

## telescope
, →  ff

## git-cz
設定ファイル：`~/changelog.config.js`  
対話形式でコミット：git cz

## zshに追加した機能
| キー | 内容 | プラグイン |
| --- | --- | --- |
| pushd 移動先のパス | 今いるパスをプッシュして移動  ※cdで自動でプッシュするようにしているため使わない| z |
| popd | 最後にプッシュしたパスに移動 | zsh |
| パス | cd無しで移動 | zsh |
| z ディレクトリ名 | 直近でアクセスしたディレクトリに移動 | zsh |
| google 検索するもの | Chromeで検索 | web-search |
| control + T | fzfを起動 | fzf |
