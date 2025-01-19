# Install Chezmoi (https://www.chezmoi.io/), if needed
# brew list chezmoi &> /dev/null || brew install chezmoi

# Ensure Chezmoi is installed
command -v chezmoi &> /dev/null || {
  echo "chezmoi not found - please install it"
  return 1 || exit 1
}

# Initialize Chezmoi
[ -d ~/.local/share/chezmoi/.git ] || chezmoi init https://github.com/chessbyte/dotfiles.git
