# Lazy-load secrets from 1Password on first use (avoids biometric prompt on shell startup)

# GitHub Token — needed for npm/npx to access @dfinitiv and @8pawns packages
ensure-github-token() {
  if [[ -z "$GITHUB_TOKEN" ]]; then
    export GITHUB_TOKEN=$(op --account $OP_ACCOUNT_BARENBOIM read "op://$OP_VAULT_CHESSBYTE/$OP_ITEM_GITHUB/access-token")
  fi
}

npm() { ensure-github-token; command npm "$@" }
npx() { ensure-github-token; command npx "$@" }
