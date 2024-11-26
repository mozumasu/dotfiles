#!/usr/bin/env bash

git clone https://github.com/SoichiroYamane/sketchybar-app-font-bg tmp_icons

# replace ttf
# move ./tmp_icons/public/dist/sketchybar-app-font-bg.ttf to $HOME/Library/Fonts/sketchybar-app-font-bg.ttf
mv ./tmp_icons/public/dist/sketchybar-app-font-bg.ttf "$HOME/Library/Fonts/sketchybar-app-font-bg.ttf"

# replace icon_map.lua
# move ./tmp_icons/public/dist/icon_map.lua to $HOME/.config/sketchybar/helpers/icon_map.lua
mv ./tmp_icons/public/dist/icon_map.lua "$HOME/.config/sketchybar/helpers/icon_map.lua"

# Cleanup: remove the cloned repository folder
rm -rf tmp_icons

echo "Font installed successfully to $HOME/Library/Fonts/sketchybar-app-font-bg.ttf"

brew services restart sketchybar
