#!/bin/bash
# Preview script for nb notes in fzf
# Enhanced version with better handling for different file types

# Extract ID from fzf input
id=$(echo "$1" | sed -E 's/^\[([^]]+)\].*/\1/')

# Check if it's an image file using nb's built-in type detection
if nb show "$id" --type image 2>/dev/null; then
  # Get the file path for image processing
  file_path=$(nb show "$id" --path 2>/dev/null)

  if [ -n "$file_path" ] && [ -f "$file_path" ]; then
    # Show file info
    nb show "$id" --info-line 2>/dev/null
    # Use du -h for file size (more portable) and stat for modified time
    echo "  Size: $(du -h "$file_path" 2>/dev/null | cut -f1)"
    echo "  Modified: $(stat -f"%Sm" -t "%b %d %H:%M" "$file_path" 2>/dev/null)"
    echo "─────────────────"

    # Try to display image using Sixel graphics (supported by fzf 0.44.0+ and WezTerm)
    if [ -f "$file_path" ]; then
      # Check if we have ImageMagick's magick command (or convert as fallback)
      if command -v magick >/dev/null 2>&1; then
        # Use ImageMagick 7's magick command to convert to sixel
        if magick "$file_path" -geometry 400x200 sixel:- 2>/dev/null; then
          exit 0
        fi
      elif command -v convert >/dev/null 2>&1; then
        # Fall back to convert command for older ImageMagick versions
        if convert "$file_path" -geometry 400x200 sixel:- 2>/dev/null; then
          exit 0
        fi
      fi

      # If Sixel display didn't work, try wezterm imgcat as fallback
      if command -v wezterm >/dev/null 2>&1; then
        wezterm imgcat --width 40 --height 20 "$file_path" 2>/dev/null && exit 0
      fi
    fi

    # If image display failed, show path only
    echo "Image preview not available"
    echo "Path: $file_path"
  fi
  exit 0
fi

# Check if it's a folder
if nb show "$id" --type folder 2>/dev/null; then
  # Show folder info
  nb show "$id" --info-line 2>/dev/null
  echo ""
  echo "📂 Folder contents:"
  echo "─────────────────"
  # List folder contents
  nb ls "$id" --limit 10 --no-color 2>/dev/null | head -20
  exit 0
fi

# Check if it's a TODO item
if echo "$1" | grep -q "✔️\|✅"; then
  # Show TODO with formatting
  nb show "$id" --info-line 2>/dev/null
  echo ""
  output=$(nb show "$id" --print 2>/dev/null)
  if [ -n "$output" ]; then
    # Check if TODO is done
    if echo "$1" | grep -q "✅"; then
      echo "✅ Status: COMPLETED"
    else
      echo "✔️  Status: TODO"
    fi
    echo "─────────────────"
    echo "$output"
  fi
  exit 0
fi

# Check if it's a bookmark
if nb show "$id" --type bookmark 2>/dev/null; then
  # Show bookmark with URL
  nb show "$id" --info-line 2>/dev/null
  echo ""
  echo "🔖 Bookmark details:"
  echo "─────────────────"
  nb show "$id" --print 2>/dev/null | head -50
  exit 0
fi

# Default handling for all other files
# Try to show content with --print first
output=$(nb show "$id" --print 2>/dev/null)
if [ -n "$output" ]; then
  # For text files, show content with file info header
  nb show "$id" --info-line 2>/dev/null
  echo "─────────────────"
  echo "$output" | head -100 # Limit preview length for performance
else
  # Show file info for binary files (non-image)
  nb show "$id" --info-line 2>/dev/null

  # Get file metadata
  file_path=$(nb show "$id" --path 2>/dev/null)
  if [ -n "$file_path" ] && [ -f "$file_path" ]; then
    echo ""
    echo "📋 File info:"
    # Use du -h for file size (more portable) and stat for modified time
    echo "  Size: $(du -h "$file_path" 2>/dev/null | cut -f1)"
    echo "  Modified: $(stat -f"%Sm" -t "%b %d %H:%M" "$file_path" 2>/dev/null)"
  fi

  # Add helpful messages for other binary file types
  if nb show "$id" --type audio 2>/dev/null; then
    echo ""
    echo "🎵 Audio file - Use 'nb show $id' to play"
  elif nb show "$id" --type video 2>/dev/null; then
    echo ""
    echo "🎬 Video file - Use 'nb show $id' to play"
  elif nb show "$id" --type archive 2>/dev/null; then
    echo ""
    echo "📦 Archive file - Use 'nb show $id' to extract"
  elif nb show "$id" --type ebook 2>/dev/null; then
    echo ""
    echo "📖 E-book file - Use 'nb show $id' to read"
  elif nb show "$id" --type document 2>/dev/null; then
    echo ""
    echo "📄 Document file - Use 'nb show $id' to open"
  fi
fi
