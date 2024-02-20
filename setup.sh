#!/bin/bash

DOTFILES_DIR="$HOME/dotfiles"

echo "シンボリックリンクを作成"
if cd "$DOTFILES_DIR"; then
    # .gitディレクトリと.DS_Storeファイルを除外し、隠しファイルを検索
     # cut で3バイト目以降を取得し、リンク先のファイルパスを取得する
     # 例: ./.config
    for file in $(find . -not -path '*/.git*' -not -path '*.DS_Store' -path '*/.*' -type f -print | cut -b 3-); do
        echo $file
    done
fi

