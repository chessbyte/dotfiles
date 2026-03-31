# Install Obsidian (https://obsidian.md/), if needed
# brew install --cask obsidian

[ -d /Applications/Obsidian.app ] || {
  echo "Obsidian not found — install with: brew install --cask obsidian"
}

export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"
