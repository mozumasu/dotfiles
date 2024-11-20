#!/bin/bash

# macOSでなければ終了
if [ "$(uname)" != "Darwin" ]; then
  echo "This script is only for macOS!"
  exit 1
fi

# Homebrewが既にインストールされているか確認
if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew..."
  if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
    echo "Failed to install Homebrew. Please check your internet connection or permissions."
    exit 1
  fi
else
  echo "Homebrew is already installed."
fi

# zshがインストールされているか確認し、インストールされていなければインストール
if ! command -v zsh >/dev/null 2>&1; then
  echo "zsh not found. Installing zsh..."
  if ! brew install zsh; then
    echo "Failed to install zsh. Please check Homebrew installation and internet connection."
    exit 1
  fi
else
  echo "zsh is already installed."
fi

# デフォルトシェルが既にzshか確認
currentShell=$(dscl . -read ~/ UserShell | sed 's/UserShell: //')
if [ "$currentShell" = "$(which zsh)" ]; then
  echo "Default shell is already zsh."
else
  # zshをデフォルトシェルとして設定
  echo "Setting zsh as default shell..."
  if ! chsh -s "$(which zsh)"; then
    echo "Failed to set zsh as default shell. You may need to enter your password."
    exit 1
  else
    echo "zsh is set as the default shell."
  fi
fi
