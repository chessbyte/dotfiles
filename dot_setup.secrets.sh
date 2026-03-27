# Lazy-load secrets from 1Password on first use (avoids biometric prompt on shell startup)

# GitHub Token — needed for npm/npx to access @dfinitiv and @8pawns packages
_ensure_github_token() {
  if [[ -z "$GITHUB_TOKEN" ]]; then
    export GITHUB_TOKEN=$(op --account $OP_ACCOUNT_BARENBOIM read "op://$OP_VAULT_CHESSBYTE/$OP_ITEM_GITHUB/access-token")
  fi
}

npm() { _ensure_github_token; command npm "$@" }
npx() { _ensure_github_token; command npx "$@" }
