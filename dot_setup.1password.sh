# Install 1Password CLI (https://formulae.brew.sh/cask/1password-cli), if needed
# brew list --cask 1password-cli &> /dev/null || brew install --cask 1password-cli

# Ensure 1Password CLI is installed
command -v op &> /dev/null || echo "1Password CLI not found - please install it"

# Initialize 1Password CLI environment variables
export OP_ACCOUNT_BARENBOIM=OBLB2ME7QRAD5JWNSDMJE7X6PA
export OP_ACCOUNT_DFINITIV=CP7KE6KD6JAJFOJFKTGG7CPAOM
export OP_ACCOUNT_8PAWNS=Q6PYA6ROGBD4RKEAAK4L2KT4WA

export OP_VAULT_CHESSBYTE=meynpb5hszg63joxh7wa2vxyi4
export OP_ITEM_GITHUB=wntvafwpyhlpkltaezxnoh662u

# Initialize 1Password SSH Agent
export SSH_AUTH_SOCK=~/.1password/agent.sock
