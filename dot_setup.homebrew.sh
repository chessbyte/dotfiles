# Install Homebrew (https://brew.sh/), if needed
[ -f /opt/homebrew/bin/brew ] || {
  echo "Homebrew not found"
  # /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

# Initialize Homebrew
[ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
