#!/bin/zsh
#エイリアスの定義・シェルプロンプトのカスタマイズ・関数の定義などを行う

COMMON_PROFILE=$HOME/dotfiles/.bin/.profile_common

if [ -e $COMMON_PROFILE ]
then source $COMMON_PROFILE
fi

#zsh固有の設定・・・