#!/bin/bash

# If it is not macos, it will end.
if [ "$(uname)" != "Darwin" ]; then
  echo "This script is only for macOS!"
  exit 1
fi

# Check if homebrew is already installed.
if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew..."
  if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
    echo "Failed to install Homebrew. Please check your internet connection or permissions."
    exit 1
  fi
else
  echo "Homebrew is already installed."
fi

# Check if zsh is installed, and if not, install it.
if ! command -v zsh >/dev/null 2>&1; then
  echo "zsh not found. Installing zsh..."
  if ! brew install zsh; then
    echo "Failed to install zsh. Please check Homebrew installation and internet connection."
    exit 1
  fi
else
  echo "zsh is already installed."
fi

# If the default shell is not zsh, set it to zsh.
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

# ----------------------------------------------------
# Mac settings
# ----------------------------------------------------
# https://github.com/kevinSuttle/macOS-Defaults
echo 'Changing MacOS settings'
# Finder settings
# Show extension
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# Show Status bar and Path bar
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
# Trackpad
defaults write -g com.apple.trackpad.scaling 8
# Key repeat
defaults write -g InitialKeyRepeat -int 12 # normal minimum is 15
defaults write -g KeyRepeat -int 1         # normal minimum is 2
