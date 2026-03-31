# Install cmux (https://cmux.dev/), if needed
# brew install --cask cmux

[ -d /Applications/cmux.app ] || {
  echo "cmux not found"
}

# Create a cmux workspace with a vertical split for a given repo
cmuxwork() {
  local dir=$PWD
  local direction=down
  local run_claude=false

  while [[ $# -gt 0 ]]; do
    case $1 in
      -d|--direction) direction=$2; shift 2 ;;
      -c|--claude) run_claude=true; shift ;;
      -*) echo "Unknown option: $1"; return 1 ;;
      *) dir=$1; shift ;;
    esac
  done

  local resolved=$(cd "$dir" && pwd)
  local name=$(basename "$resolved")
  local cmd="cmux rename-workspace \"$name\" && cmux new-split $direction"

  if [[ $run_claude == true ]]; then
    cmd="$cmd && claude"
  fi

  cmux new-workspace --cwd "$resolved" --command "$cmd"
}
