# Install Obsidian (https://obsidian.md/), if needed
# brew install --cask obsidian

[ -d /Applications/Obsidian.app ] || {
  echo "Obsidian not found"
}

export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"
