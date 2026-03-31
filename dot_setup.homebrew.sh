# Install Homebrew (https://brew.sh/), if needed
# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

[ -f /opt/homebrew/bin/brew ] || {
  echo "Homebrew not found"
}

# Initialize Homebrew
[ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"

# Add zsh-completions to FPATH (brew shellenv doesn't include this)
[ -d "$(brew --prefix)/share/zsh-completions" ] && FPATH="$(brew --prefix)/share/zsh-completions:$FPATH"
