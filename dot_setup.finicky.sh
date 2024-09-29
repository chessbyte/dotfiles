#!/bin/bash

# Install Finicky (https://formulae.brew.sh/cask/finicky), if needed
# brew list --cask finicky &> /dev/null || brew install --cask finicky

# Directory to search for Chrome Profiles
CHROME_DIR="$HOME/Library/Application Support/Google/Chrome"

# In-memory dictionary mapping emails to env var names
declare -A EMAIL_MAP
EMAIL_MAP=(
    ["oleg.barenboim@gmail.com"]="CHROME_PROFILE_PERSONAL"
    ["chessbyte@gmail.com"]="CHROME_PROFILE_CHESSBYTE"
    ["oleg.barenboim@dfinitiv.io"]="CHROME_PROFILE_DFINITIV"
    ["oleg.barenboim@8pawns.com"]="CHROME_PROFILE_8PAWNS"
    ["oleg@8pawns.com"]="CHROME_PROFILE_8PAWNS"
)

# Loop through all JSON files in the Chrome profile directories
find "$CHROME_DIR" -type f -name "Preferences" -maxdepth 2 | while IFS= read -r json_file; do
    # Extract the email using jq (assuming the JSON structure has an "email" field)
    email=$(jq -r '.account_info[0].email' "$json_file" 2>/dev/null)

    # Check if jq was successful in extracting an email and if it exists in the dictionary
    if [[ -n "$email" && "$email" != "null" && -n "${EMAIL_MAP[$email]}" ]]; then
        # Get the profile directory name (e.g., "Profile 1" or "Default")
        PROFILE_DIR=$(basename "$(dirname "$json_file")")

        # Get the environment variable name from the dictionary
        VAR_NAME=${EMAIL_MAP[$email]}

        # Set the environment variable with the profile directory name as the value
        export "$VAR_NAME"="$PROFILE_DIR"
    fi
done
